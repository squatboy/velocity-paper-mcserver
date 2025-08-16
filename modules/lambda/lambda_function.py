import os
import json
import logging
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# 로거 설정
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Discord 웹훅 URL 환경 변수에서 가져오기
DISCORD_WEBHOOK_URL = os.environ.get("DISCORD_WEBHOOK_URL")


def lambda_handler(event, context):
    """
    SNS 메시지를 수신하여 Discord 웹훅으로 전송하는 Lambda 핸들러
    """
    logger.info("Lambda invoked. Webhook configured: %s", bool(DISCORD_WEBHOOK_URL))
    if not DISCORD_WEBHOOK_URL:
        logger.error("Discord 웹훅 URL이 설정되지 않았습니다.")
        return {"statusCode": 500, "body": "환경 변수 오류"}

    try:
        # 이벤트 기본 로깅 (민감정보 최소화)
        record_count = len(event.get("Records", [])) if isinstance(event, dict) else 0
        logger.info("Incoming SNS records: %d", record_count)

        if record_count == 0:
            logger.error("SNS Records가 비어있습니다: %s", json.dumps(event)[:500])
            return {"statusCode": 400, "body": "잘못된 이벤트 형식"}

        raw_message = event["Records"][0]["Sns"].get("Message", "")
        logger.info("Raw SNS message (truncated): %s", raw_message[:500])

        # SNS 메시지 파싱: JSON 우선, 실패 시 평문 처리
        try:
            sns_message = json.loads(raw_message)
        except Exception:
            sns_message = {"Message": raw_message}

        # CloudWatch 알람 형식 우선 처리
        alarm_name = sns_message.get("AlarmName", "Unknown Alarm")
        alarm_description = sns_message.get(
            "AlarmDescription", sns_message.get("Message", "설명 없음")
        )
        new_state_reason = sns_message.get("NewStateReason", "사유 미제공")
        region = sns_message.get("Region", os.environ.get("AWS_REGION", "us-east-1"))

        alarm_arn = sns_message.get("AlarmArn")
        alarm_id = alarm_arn.split(":")[-1] if alarm_arn else alarm_name
        alarm_url = f"https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#alarmsV2:alarm/{alarm_id}"

        discord_message = {
            "embeds": [
                {
                    "title": f"🚨 CloudWatch 알림: {alarm_name}",
                    "description": str(alarm_description)[:4000],
                    "url": alarm_url,
                    "color": 15158332,
                    "fields": [
                        {
                            "name": "상태 변경 사유",
                            "value": str(new_state_reason)[:1024],
                            "inline": False,
                        },
                        {"name": "리전", "value": region, "inline": True},
                        {"name": "알람 이름", "value": alarm_name, "inline": True},
                    ],
                    "footer": {"text": "AWS CloudWatch Monitoring"},
                }
            ]
        }

        # Discord 웹훅으로 POST 요청 전송
        req = Request(
            DISCORD_WEBHOOK_URL,
            json.dumps(discord_message).encode("utf-8"),
            {"Content-Type": "application/json"},
        )

        with urlopen(req) as response:
            status = getattr(response, "status", 200)
            response.read()
            # Discord는 성공 시 204 No Content를 반환하기도 함
            if status in (200, 204):
                logger.info(
                    "Discord로 메시지를 성공적으로 전송했습니다. status=%s", status
                )
                return {"statusCode": status, "body": "메시지 전송 성공"}
            else:
                logger.error("Discord 응답 코드 비정상: %s", status)
                return {"statusCode": status, "body": f"Discord status {status}"}

    except HTTPError as e:
        logger.error("HTTP 에러 발생: %s %s", e.code, e.reason)
        return {"statusCode": e.code, "body": str(e.reason)}
    except URLError as e:
        logger.error("URL 에러 발생: %s", e.reason)
        return {"statusCode": 500, "body": str(e.reason)}
    except Exception as e:
        logger.error("알 수 없는 에러 발생: %s", e)
        return {"statusCode": 500, "body": str(e)}
