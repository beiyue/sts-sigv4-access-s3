# 基于AWS STS服务使用V4签名访问S3

在一些智能家居场景设备资源有限，官方SDK体积过大，这里提供了一种替代思路自行封装V4签名方式来访问S3。


### 内容框架

#### [创建新用户]

登录AWS Console后台，选择服务，在搜索框中选择“IAM”，在IAM左侧选择“用户”，创建用户名为“s3-test-user”,勾选访问类型“编程访问”
生成AK/SK：

```Bash
Access key ID ：AKIARKSM4QPXGEUXXXXXX
Secret access key：v645s/S1fiZy/+9KjmP3YxQ+cL70qiiXXXXXXXX
```

#### [创建角色]

创建IAM Role，选择“其他AWS账户”，填入账户ID，这里简单设置为登录的账号即可。角色名称输入“sts-test”
生成的 Role ARN：arn:aws:iam::XXXXX:role/sts-test
这里需要修改Role的trust relationship policy,选择“编辑信任关系”，将root替换为s3-test-user,修改如下：
```Bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::0914293XXXXX:user/s3-test-user"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
#### [测试用户权限]
直接使用 AK/SK，查看用户是否有相应的权限，使用 aws configure 配置：
```
$ aws configure --profile s3-test-user
AWS Access Key ID [None]: AKIARKSM4QPXGXXXXX
AWS Secret Access Key [None]: v645s/S1fiZy/+9KjmP3YxQ+cL70qiiMJYugXXXXX
Default region name [None]: ap-southeast-1
Default output format [None]: json 
```
备注：我这里选择的是新加坡，根据需要也可以改为国内区域或海外其他区域
```
aws sts get-caller-identity --profile s3-test-user
{
    "UserId": "AIDARKSM4QPXNAZNXXXXXX",
    "Account": "0XXXXXX",
    "Arn": "arn:aws:iam::091429XXXXX:user/s3-test-user"
}
```
测试通过

#### [获取临时凭证]
```
sudo vim ~/getSTS.sh

aws sts assume-role --role-arn arn:aws-cn:iam::<ACCOUNT_ID >:role/<ROLE_NAME> --role-session-name $1 > sts.txt

#将console Role ARN拷贝替换--role-arn， 例如：--role-arn  arn:aws:iam::0914293XXXXX:role/sts-test

aws sts assume-role --role-arn arn:aws:iam::0914293XXXXX:role/sts-test --role-session-name $1 > sts.txt

#执行test.sh脚本
sudo ./getSTS.sh  ${RANDOM} 
```

#### [Shell实现V4签名 PUT/GET 访问 S3]
```
#method=$1
#canonical_uri=$2
#file_name=$3

Examples:

sudo ./test.sh PUT \Develop_Bucket\devices\jpg\test.jpeg   /home/ubuntu/test.jpeg

#执行test.sh脚本
sudo ./test.sh 	PUT  \<BUCKET_PATH>\test.jpeg  /home/ubuntu/test.jpeg
```
