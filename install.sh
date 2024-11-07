
#######################################################

read -p "Dominio (ex: seudominio.com): " dominio
echo ""
read -p "Admin Email (ex: contato@dominio.com): " email
echo ""

#######################################################

echo ""
echo ""
echo ""

echo "Atualizando a VPS + Instalando Docker Compose + Nginx + Certbot"

cd
cd

clear

sudo apt update -y
sudo apt upgrade -y

apt install docker-compose -y
sudo apt update

sudo apt install nginx -y
sudo apt update

sudo apt install certbot -y
sudo apt install python3-certbot-nginx -y
sudo apt update

mkdir typebot.io
cd typebot.io
echo ""
echo ""
echo "Atualizado/Instalado com Sucesso"

clear

#######################################################

echo "Criando arquivo docker-compose.yml"

sleep 3

cat > docker-compose.yml << EOL
version: '3.3'
services:
  typebot-db:
    image: postgres:13
    restart: always
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=typebot
      - POSTGRES_PASSWORD=typebot
  typebot-builder:
    ports:
      - 4001:3000
    image: baptistearno/typebot-builder:latest
    restart: always
    depends_on:
      - typebot-db
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - NEXTAUTH_URL=https://painel.$dominio
      - NEXT_PUBLIC_VIEWER_URL=https://viwer.$dominio
 
      - ENCRYPTION_SECRET=ef3b859ed1f6452598e7dd51f23e4345
 
      - ADMIN_EMAIL=$email
 
      - SMTP_HOST=smtp.gmail.com
      - SMTP_USERNAME=adriel020920@gmail.com
      - SMTP_PASSWORD=qvwdewgdzexnxtsp
      - NEXT_PUBLIC_SMTP_FROM='Suporte' <adriel020920@gmail.com>
 
      - DISABLE_SIGNUP=false
 
      - S3_ACCESS_KEY=minio
      - S3_SECRET_KEY=minio123
      - S3_BUCKET=typebot
      - S3_ENDPOINT=banco.$dominio
  typebot-viewer:
    ports:
      - 4002:3000
    image: baptistearno/typebot-viewer:latest
    restart: always
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - NEXTAUTH_URL=https://painel.$dominio
      - NEXT_PUBLIC_VIEWER_URL=https://viwer.$dominio
      - ENCRYPTION_SECRET=ef3b859ed1f6452598e7dd51f23e4345
 
      - S3_ACCESS_KEY=minio
      - S3_SECRET_KEY=minio123
      - S3_BUCKET=typebot
      - S3_ENDPOINT=banco.$dominio
  mail:
    image: bytemark/smtp
    restart: always
  minio:
    image: minio/minio
    command: server /data
    ports:
      - '9001:9000'
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    volumes:
      - s3_data:/data
  createbuckets:
    image: minio/mc
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      sleep 10;
      /usr/bin/mc config host add minio http://minio:9000 minio minio123;
      /usr/bin/mc mb minio/typebot;
      /usr/bin/mc anonymous set public minio/typebot/public;
      exit 0;
      "
volumes:
  db_data:
  s3_data:
EOL

echo "Criado e configurado com sucesso"

clear



###############################################

cd

cat > typebot << EOL
server {

  server_name painel.$dominio;

  location / {

    proxy_pass http://127.0.0.1:4001;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    
    proxy_cache_bypass \$http_upgrade;

	  }

  }
EOL

###############################################

sudo mv typebot /etc/nginx/sites-available/

sudo ln -s /etc/nginx/sites-available/typebot /etc/nginx/sites-enabled

###############################################

cd

cat > bot << EOL
server {

  server_name viwer.$dominio;

  location / {

    proxy_pass http://127.0.0.1:4002;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    
    proxy_cache_bypass \$http_upgrade;

	  }

  }
EOL

###############################################

sudo mv bot /etc/nginx/sites-available/

sudo ln -s /etc/nginx/sites-available/bot /etc/nginx/sites-enabled

##################################################

cd

cat > storage << EOL
server {

  server_name banco.$dominio;

  location / {

    proxy_pass http://127.0.0.1:9001;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    
    proxy_cache_bypass \$http_upgrade;

	  }

  }
EOL


sudo mv storage /etc/nginx/sites-available/

sudo ln -s /etc/nginx/sites-available/storage /etc/nginx/sites-enabled

sudo certbot --nginx --email $email --redirect --agree-tos -d painel.$dominio -d viwer.$dominio -d banco.$dominio

###############################################

echo "Iniciando Conteiner"

cd typebot.io
docker-compose up -d

echo "Typebot Instaldo... Realizando Proxy Reverso"


clear
