#/bin/bash
set -xe

default_conf_dir=/home/docker/lnmp
read -p "conf_dir default:${default_conf_dir}" conf_dir
if [ ! $conf_dir ];then
  conf_dir=$default_conf_dir
fi

echo "start nginx conf"
docker run -it -d --name nginx-test nginx:latest
mkdir -p $conf_dir/nginx/conf
chmod -R 777 $conf_dir/nginx/conf
docker cp nginx-test:/etc/nginx/. $conf_dir/nginx/conf
docker rm -f nginx-test
cp -f $conf_dir/nginx/conf/nginx.conf $conf_dir/nginx/conf/nginx.bak
cp -f nginx/nginx.conf $conf_dir/nginx/conf/
cp -f nginx/default.conf $conf_dir/nginx/conf/conf.d/
mkdir -p $conf_dir/nginx/html/default
cp -f php7.4/index.php $conf_dir/nginx/html/default/
mkdir -p $conf_dir/nginx/log
chmod -R 777 $conf_dir/nginx/log
echo "end nginx conf"

echo "start php-fpm"
docker run -it -d --name php-test php:7.4-fpm
mkdir -p $conf_dir/php-fpm7.4/conf
docker cp php-test:/usr/local/etc/. $conf_dir/php-fpm7.4/conf/
docker rm -f php-test
if cat $conf_dir/php-fpm7.4/conf/php/conf.d/docker-php-ext-sodium.ini | grep "redis" > /dev/null
then
  echo "extension=redis"
else
  echo "extension=redis" >> $conf_dir/php-fpm7.4/conf/php/conf.d/docker-php-ext-sodium.ini
fi
cp -f $conf_dir/php-fpm7.4/conf/php-fpm.d/www.conf $conf_dir/php-fpm7.4/conf/php-fpm.d/www.bak
cp -f php7.4/php-fpm.conf $conf_dir/php-fpm7.4/conf/php-fpm.d/www.conf
mkdir -p $confi_dir/php-fpm7.4/logs
chmod -R 777 $confi_dir/php-fpm7.4/logs
echo "end php-fpm"

echo "start mysql conf"
docker run -it -d -e MYSQL_ROOT_PASSWORD=123456 --name mysql-test mysql:5.7.39
until docker logs mysql-test | grep 'ready for connections'
do
	mkdir -p $conf_dir/mysql/etc
	mkdir -p $conf_dir/mysql/data
	chmod -R 777 $conf_dir/mysql/data
	docker cp mysql-test:/etc/my.cnf $conf_dir/mysql/etc/
	docker cp mysql-test:/var/lib/mysql/. $conf_dir/mysql/data/
done
docker rm -f mysql-test
echo "end mysql conf"

echo "start redis conf"
mkdir -p $conf_dir/redis/conf
cp -f redis/redis.conf $conf_dir/redis/conf/
mkdir -p $conf_dir/redis/data $conf_dir/redis/logs
chmod -R 777 $conf_dir/redis/data
chmod -R 777 $conf_dir/redis/logs
echo "end redis conf"

echo "start docker-compose up"
cp -f docker-compose.yml docker-compose.yml.bak
sed -i "s#/home/docker/lnmp#${conf_dir}#g" docker-compose.yml
docker-compose up -d
echo "end docker-compose"
