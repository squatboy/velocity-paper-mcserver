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
    if not DISCORD_WEBHOOK_URL:
        logger.error("Discord 웹훅 URL이 설정되지 않았습니다.")
        return {"statusCode": 500, "body": "환경 변수 오류"}

    try:
        # SNS 메시지 추출
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        alarm_name = sns_message['AlarmName']
        alarm_description = sns_message.get('AlarmDescription', '설명 없음')
        new_state_reason = sns_message['NewStateReason']
        region = sns_message['Region']
        
        # CloudWatch 알람 링크 생성
        alarm_arn = sns_message['AlarmArn']
        alarm_id = alarm_arn.split(':')[-1]
        alarm_url = f"https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#alarmsV2:alarm/{alarm_id}"

        # Discord 메시지 형식 생성
        discord_message = {
            "embeds": [
                {
                    "title": f"🚨 CloudWatch 알림: {alarm_name}",
                    "description": alarm_description,
                    "url": alarm_url,
                    "color": 15158332,  # 빨간색
                    "fields": [
                        {
                            "name": "상태 변경 사유",
                            "value": new_state_reason,
                            "inline": False
                        },
                        {
                            "name": "리전",
                            "value": region,
                            "inline": True
                        },
                        {
                            "name": "알람 이름",
                            "value": alarm_name,
                            "inline": True
                        }
                    ],
                    "footer": {
                        "text": "AWS CloudWatch Monitoring"
                    }
                }
            ]
        }

        # Discord 웹훅으로 POST 요청 전송
        req = Request(DISCORD_WEBHOOK_URL, json.dumps(discord_message).encode('utf-8'), {'Content-Type': 'application/json'})
        
        with urlopen(req) as response:
            response.read()
            logger.info("Discord로 메시지를 성공적으로 전송했습니다.")
            return {"statusCode": 200, "body": "메시지 전송 성공"}

    except HTTPError as e:
        logger.error(f"HTTP 에러 발생: {e.code} {e.reason}")
        return {"statusCode": e.code, "body": str(e.reason)}
    except URLError as e:
        logger.error(f"URL 에러 발생: {e.reason}")
        return {"statusCode": 500, "body": str(e.reason)}
    except Exception as e:
        logger.error(f"알 수 없는 에러 발생: {e}")
        return {"statusCode": 500, "body": str(e)}
