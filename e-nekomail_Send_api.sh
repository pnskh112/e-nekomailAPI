#!/bin/bash
export DISPLAY='unix:0.0'
# 認証キーセット
srcName="e-nekomail_Send_api.sh"
mailId=""
filename="request.body"
# 送信するZIPファイル名
# file="\/home\/dycsales\/data\/download\/csv\/yamato_senddata.zip"
# file="\/home\/vagrant\/watir_src\/Ruby\/testmailaddress.txt"
file="./testmail.txt"
mailAddress="aaa@example.com"
mailStatusMonitorTimer=""
OcpApimSubscriptionKey="xxxhogexxx"
requesturi="https://fcms.i-securedeliver.jp"
log="/home/vagrant/watir_src/Ruby/logs/delive_export_logs/e-nekomail_Send.log"
# log="/home/sou/project_share/e-nekomailAPI/log/e-nekomail_Send.log"
echo "------------------------------------------------" >> $log 2>&1
echo "${srcName} is start." >> $log 2>&1
# メール情報登録APIを実行。メールIDを取得
echo $json >> $log 2>&1
echo "Access mailApi Start" >> $log 2>&1
echo "https://fcms.i-securedeliver.jp/sdms/mails/add" >> $log 2>&1
# 引取期限セット
        # 例）echo $responseJson | jq -r '.iwsdfile[].id' >> $fileId
        # # 引き取り期限(1週間後を指定する例)
        # days7=date"+%Y/%m/%d" -d "7 days"
        
        # # 返信期限(1カ月後を指定する例)
        # month1=date"+%Y/%m/%d" -d "1 month"
# リクエストボディの定義
# リクエストとレスポンスを表示するオプション付きのcurlコマンド
# curl --verbose \
#       -X GET \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d "$json" "$requesturi/sdms/mails/history/1" >/dev/null
res=`curl  -X POST "https://fcms.i-securedeliver.jp/sdms/mails/add"\
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      --data-binary @- <<EOF | jq
{
    "repositoryType": 2,
    "attachedFiles": [
        {
            "fileName": "testmail.txt"
        }
    ],
    "downloadDeadline": "2020-09-24T00:00:00.000Z",
    "downloadReminder": {},
    "language": "JAPANESE",
    "title": "testTitle",
    "comment": "Comment Test",
    "receivers": [
        {
            "mailAddress1": ${mailAddress}
        }
    ]
}
`
EOF
echo "Access mailApi End" >> $log 2>&1
echo ${res} >> $log 2>&1
# メールID取得
mailId=`echo ${res} | jq '.id'`
echo ${mailId} >> $log 2>&1
# # ファイルID取得
fileId=`echo ${res} | jq -r '.attachedFiles[].id'`
echo ${fileId} >> $log 2>&1
# ファイル登録API実行
echo "Access fileApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/$mailId/resume/$fileId" >> $log 2>&1
# リクエストとレスポンスを表示するオプション付きのcurlコマンド
# curl --verbose \
#       -X GET \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d "$json" "$requesturi/sdms/mails/$mailId/resume/$fileId" >/dev/null
res2=`curl -X POST "$requesturi/sdms/mails/$mailId/resume/$fileId" \
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: multipart/form-data" \
      -F "file=@$file"
`
echo ${res2json}
echo ${res2}
echo "Access fileApi End" >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
# タスク結果取得API実行
echo "Access taskApi Start" >> $log 2>&1
# リクエストとレスポンスを表示するオプション付きのcurlコマンド
# curl --verbose \
#       -X GET \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       -d "$json" "$requesturi/sdms/mails/$mailId"  >/dev/null
res3=`curl  -X GET "$requesturi/sdms/mails/history/$mailId"\
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      --data-binary @- <<EOF | jq
	{
		"mailId": ${mailId}
	}
EOF
`
# ステータス取得
status=`echo ${res3} | jq -r '.status'`
echo ${res3}
echo ${status}
if [ $status = "FINISHED" ]; then
    echo "status is FINISHED!" >> $log 2>&1
fi
echo "Access taskApi End" >> $log 2>&1
echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
