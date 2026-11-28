系统
System	代码仓库
Code Repository
eBest OMS	GitLab  https://g.donkibuy.com/ebest/oms

eBest WMS	GitLab  https://g.donkibuy.com/ebest/wms


我们现在已经在开始安排交接，最好是ebest自己来开发这个功能，当熟悉项目，有问题还可以问我们，开发注意事项：
1. 以 develop为基础分支，分支合并develop会部署 测试环境（wms也有测试环境）
2. 功能测试没问题，才能合并到master, ci自动部署production


# ci自动部署production

???

# AWS related

With the AWS CLI (your own credentials need S3 delete and CloudFront invalidation permission):
aws s3 rm s3://<bucket>/images/1bf3568d-xxxx-photo.png
aws cloudfront create-invalidation --distribution-id EQBQSAG176B64 --paths "/images/1bf3568d-xxxx-photo.png"