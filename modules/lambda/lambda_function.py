import os
import json
import urllib.request

DISCORD_WEBHOOK_URL = os.environ.get("DISCORD_WEBHOOK_URL")


def lambda_handler(event, context):
    try:
        for record in event["Records"]:
            sns_message_raw = record["Sns"]["Message"]
            try:
                sns_message = json.loads(sns_message_raw)
            except json.JSONDecodeError:
                sns_message = {}

            is_alarm = "AlarmName" in sns_message

            if is_alarm:
                alarm_name = sns_message.get("AlarmName", "Unknown Alarm")
                alarm_description = sns_message.get(
                    "AlarmDescription", sns_message.get("Message", "설명 없음")
                )
                new_state_reason = sns_message.get("NewStateReason", "사유 미제공")
                region = "ap-northeast-2"
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
                                {
                                    "name": "알람 이름",
                                    "value": alarm_name,
                                    "inline": True,
                                },
                            ],
                            "footer": {"text": "AWS CloudWatch Monitoring"},
                        }
                    ]
                }
            else:
                text = sns_message.get("Message") or sns_message_raw
                discord_message = {"content": str(text)[:1900]}

            data = json.dumps(discord_message).encode("utf-8")

            req = urllib.request.Request(
                DISCORD_WEBHOOK_URL,
                data=data,
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": "Mozilla/5.0",
                },
                method="POST",
            )

            with urllib.request.urlopen(req) as response:
                response.read()

        return {"statusCode": 200, "body": "Discord notification sent."}
    except Exception as e:
        print(f"Error sending Discord notification: {e}")
        return {"statusCode": 500, "body": str(e)}
