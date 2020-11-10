#!/bin/bash -eu
export DISPLAY='unix:0.0'
#*******************************************************************************
# e-nekomail_Send.sh
#
#    概要        ： e-ネコセキュアデリバー　送信
#
#    履歴        ：2020/09/28 Create by hoge
#
#*******************************************************************************

# 認証キーセット
OcpApimSubscriptionKey="---hoge---"
srcName="e-nekomail_Send_api.sh"
requesturi="https://fcms.i-securedeliver.jp"

# 送信するZIPファイル
# 本番時は上に修正
# file="/home/dycsales/data/download/csv/yamato_senddata.zip"
file="./testmail.txt"

# 送信時ファイル名をセット
# 本番時は上に修正
# fileName='"fileName" : "yamato_senddata.zip"'
fileName='"fileName" : "testmail.txt"'

# 送信時メールアドレス
# mailAddress1=""
mailAddress1="aaa@example.com"

# mailId初期値
mailId=""

# ログ出力用現在時刻取得
logTime=`date +%Y%m%d_%H%M%S`

# 本番時は上に修正
# log="/home/dycsales/data/logs/delive_export_logs/e-nekomail_Send_${logTime}.log"
log="/home/vagrant/watir_src/Ruby/logs/delive_export_logs/e-nekomail_Send_${logTime}.log"

# メイン処理開始
echo "------------------------------------------------" >> $log 2>&1
echo "${srcName} is start." >> $log 2>&1

# メール情報登録APIを実行。メールIDを取得
echo "Access mailApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/add" >> $log 2>&1

# 引き取り期限(1週間後)セット
downloadDeadline=`date "+%Y-%m-%dT00:00:00.000Z" -d "7 days"`

# リクエストボディの定義
echo "メール情報登録API実行" >> $log 2>&1

res=`curl -X POST "$requesturi/sdms/mails/add"\
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      --data-binary @- <<EOF | jq
{
    "repositoryType": 2,
    "attachedFiles":[
        {
            ${fileName}
        }
	],
    "downloadDeadline": "${downloadDeadline}",
    "downloadReminder": {},
    "language": "JAPANESE",
    "title": "testTitle",
    "comment": "Comment Test",
    "receivers": 
    [
        {
            "mailAddress1": "${mailAddress1}"
        }
    ]
}
EOF
`
# リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
# res=`curl --verbose \
#       -X POST "https://fcms.i-securedeliver.jp/sdms/mails/add"\
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       --data-binary @- <<EOF | jq
# {
#     "repositoryType": 2,
#     "attachedFiles":[
#         {
#             ${fileName}
#         }
# 	],
#     "downloadDeadline": "${downloadDeadline}",
#     "downloadReminder": {},
#     "language": "JAPANESE",
#     "title": "testTitle",
#     "comment": "Comment Test",
#     "receivers": 
#     [
#         {
#             "mailAddress1": "${mailAddress1}"
#         }
#     ]
# }
# EOF
# `

echo ${res} >> $log 2>&1


echo "Access mailApi End" >> $log 2>&1

# メールID取得
mailId=`echo ${res} | jq '.id'`
echo "メールID：${mailId}" >> $log 2>&1

# ファイルID取得
fileId=`echo ${res} | jq -r '.attachedFiles[].id'`
echo "ファイルID:${fileId}" >> $log 2>&1

# ファイル登録API実行
echo "ファイル登録API実行" >> $log 2>&1
echo "Access fileApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/$mailId/resume/$fileId" >> $log 2>&1

# タイムアウト対策のため、3回処理実施
for i in 0 1 2; do

  res2=`curl -X POST "$requesturi/sdms/mails/$mailId/resume/$fileId" \
       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
       -H "Content-Type: multipart/form-data" \
       -F "file=@$file"
  `
  
  # リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
  # res2=`curl --verbose \
  #       -X POST "$requesturi/sdms/mails/$mailId/resume/$fileId" \
  #       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
  #       -H "Content-Type: multipart/form-data" \
  #       -F "file=@$file"
  # `
  
  echo ${res2} >> $log 2>&1
  
  # 変数resに対して、JSON形式で値チェック行い、コール数上限エラー出た際1分スリープ入れる。
  if [ $i != 9 ]; then
###   if [[  $( echo $res2 | jq 'select(contains({ statusCode: 429 }))') ]]; then
      echo "-------------------------------------------------------------"
      echo "コール数上限のレスポンスがセキュアデリバーより返されました。"
      echo "1分間スリープの後、再度実行致します。"
      echo "-------------------------------------------------------------"
      sleep 1m
  # コール数上限エラーなく、ファイル登録時のレスポンス返ってくればループ抜ける
  ### else if [[ $( echo $res | jq 'select(.attachedFiles != "NULL")')  ]]; then
  else
      break
  fi

  if [ $i -eq 2 ]; then
      echo "タイムアウトします。システム担当へご連絡ください。"
      exit 1
  fi

done

echo "Access fileApi End" >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1

# タスク結果取得API実行
echo "タスク結果取得API実行" >> $log 2>&1
echo "Access taskApi Start" >> $log 2>&1
res3=`curl  -X GET "$requesturi/sdms/mails/history/$mailId"\
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      --data-binary @- <<EOF | jq
	{
		"mailId": ${mailId}
	}
EOF
`
# リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
# res3=`curl --verbose \
#       -X GET "$requesturi/sdms/mails/history/$mailId"\
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       --data-binary @- <<EOF | jq
# 	{
# 		"mailId": ${mailId}
# 	}
# EOF
# `

# ステータス取得
echo "ステータス取得" >> $log 2>&1
status=`echo ${res3} | jq -r '.status'`
echo ${res3} >> $log 2>&1
echo ${status} >> $log 2>&1
# タスク結果を取得して、「FINISHED」であれば終了
if [ $status = "FINISHED" ]; then
    echo "status is FINISHED!" >> $log 2>&1
else
    echo "タスク結果APIから${status}返りました。システム担当へご連絡ください。" >> $log 2>&1
    exit 1
fi
echo "Access taskApi End" >> $log 2>&1
echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
exit 0

echo ${res} >> $log 2>&1
echo "Access mailApi End" >> $log 2>&1

# メールID取得
mailId=`echo ${res} | jq '.id'`
echo "メールID：${mailId}" >> $log 2>&1

# ファイルID取得
fileId=`echo ${res} | jq -r '.attachedFiles[].id'`
echo "ファイルID:${fileId}" >> $log 2>&1

# ファイル登録API実行
echo "ファイル登録API実行" >> $log 2>&1
echo "Access fileApi Start" >> $log 2>&1
echo "$requesturi/sdms/mails/$mailId/resume/$fileId" >> $log 2>&1

# タイムアウト対策のため、3回処理実施
for i in {1..3};
do

###res2=`curl -X POST "$requesturi/sdms/mails/$mailId/resume/$fileId" \
###      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
###      -H "Content-Type: multipart/form-data" \
###      -F "file=@$file"
###`

# リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
# res2=`curl --verbose \
#       -X POST "$requesturi/sdms/mails/$mailId/resume/$fileId" \
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: multipart/form-data" \
#       -F "file=@$file"
# `

echo ${res2} >> $log 2>&1

# 変数resに対して、JSON形式で値チェック行い、コール数上限エラー出た際3分スリープ入れる。
if [[  $( echo $res2 | jq 'select(contains({ statusCode: 429 }))') ]]; then
    echo "-------------------------------------------------------------"
    echo "コール数上限のレスポンスがセキュアデリバーより返されました。"
    echo "1分間スリープの後、再度実行致します。"
    echo "-------------------------------------------------------------"
    sleep 1m
# 上限エラーなく、ファイル登録時のレスポンス返ってくればループ抜ける
else if [[ $( echo $res | jq 'select(.attachedFiles != "NULL")')  ]]; then
    break
fi

if [ $i -eq 3]; then
    echo "タイムアウトします。システム担当へご連絡ください。"
    exit
fi

done



echo "Access fileApi End" >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1

# タスク結果取得API実行
echo "タスク結果取得API実行" >> $log 2>&1
echo "Access taskApi Start" >> $log 2>&1
res3=`curl  -X GET "$requesturi/sdms/mails/history/$mailId"\
      -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
      -H "Content-Type: application/json" \
      --data-binary @- <<EOF | jq
	{
		"mailId": ${mailId}
	}
EOF
`
# リクエストとレスポンスを表示するオプション付きのcurlコマンド(障害時のデバッグに利用)
# res3=`curl --verbose \
#       -X GET "$requesturi/sdms/mails/history/$mailId"\
#       -H "Ocp-Apim-Subscription-Key: $OcpApimSubscriptionKey" \
#       -H "Content-Type: application/json" \
#       --data-binary @- <<EOF | jq
# 	{
# 		"mailId": ${mailId}
# 	}
# EOF
# `

# ステータス取得
echo "ステータス取得" >> $log 2>&1
status=`echo ${res3} | jq -r '.status'`
echo ${res3} >> $log 2>&1
echo ${status} >> $log 2>&1
if [ $status = "FINISHED" ]; then
    echo "status is FINISHED!" >> $log 2>&1
else
    exit 1
fi
echo "Access taskApi End" >> $log 2>&1
echo "${srcName} is end." >> $log 2>&1
echo "------------------------------------------------" >> $log 2>&1
exit 0
