Структура читается как:

  infra/ - Это инфраструктура как код

    Terraform -> создает ВМ в yandex cloud
    Ansible -> настраивает ВМ (Docker, k3s, nginx, мониторинг)

  app/ - сам продукт, нам не важно, что это за продукт, важно, как оно собирается, тесты и деплои.

    fastapi, dockerfile, тесты.

  k8s/ - кубер манифесты

  monitoring/ - наблюдаемость

  vault/ - управление секретами

  Makefile -  единая точка управления

  .gitlab-ci.yml - CI/CD

начинаем terraform:

  1) устанавливаем зависимости
    sudo apt update
    sudo apt install -y gnupg software-properties-common curl
  2) добавляем GPG ключ
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  3) добавляем репозиторий
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \ https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
  4) устанавливаем terraform
    sudo apt update
    sudo apt install terraform
  5) если не удалось, то качаем файл на локальную тачку через впн, т.к. hashicorp не поддерживается в рф, далее переносим наш архив в ВМ и устанавливаем
    scp -i ~/.ssh/key terraform_1.14.4_linux_amd64.zip admin@<VM_IP>:/tmp/
    cd /tmp
    sudo apt install -y unzip
    unzip terraform_1.14.4_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform

далее установка Yandex CLI:

  1) устанавливаем Yandex CLI
    curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
    yc version
  2) начинаем настройку и проверяем
    yc init
    yc resource-manager cloud list
    yc resource-manager folder list
  3) создаем токен
    yc iam create-token
  4) создаем ключ на локальной машине
    ssh-keygen -t ed25519 -f ~/.ssh/devops -C "devops-key"
    cat ~/.ssh/devops.pub
  5) прописываем все в в папке terraform/yandex
  6) добавляем ключ Service Account + key.json
    а) Создаем service account в нужной папке
      SA_NAME="tf-sa"
      yc iam service-account create --name "$SA_NAME"
    б) Даем ему права на folder (для учебного стенда хватит editor)
      FOLDER_ID="$(yc config get folder-id)"
      SA_ID="$(yc iam service-account get "$SA_NAME" --format json | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"

      yc resource-manager folder add-access-binding "$FOLDER_ID" \
        --role editor \
        --subject serviceAccount:"$SA_ID"
    в) Создаем ключ и кладем в домашнюю директорию
      mkdir -p ~/.yc
      yc iam key create --service-account-name "$SA_NAME" --output ~/.yc/sa-key.json
      chmod 600 ~/.yc/sa-key.json
  7) закидываем провайдера, скачанного с https://github.com/yandex-cloud/terraform-provider-yandex/releases на нашу ВМ командой
    scp -i ~/.ssh/key terraform-provider-yandex_0.190.0_linux_amd64.zip admin@<VM_IP>:/tmp/

    создаем зеркало папку и распаковываем туда наш файл
    mkdir -p "$HOME/tf-mirror"
    VER="0.190.0"
    OS="linux"
    ARCH="amd64"

    DEST="$HOME/tf-mirror/registry.terraform.io/yandex-cloud/yandex/${VER}/${OS}_${ARCH}"
    mkdir -p "$DEST"

    unzip -o "/tmp/terraform-provider-yandex_${VER}_${OS}_${ARCH}.zip" -d "$DEST"
    chmod +x "$DEST"/terraform-provider-yandex*
    ls -la "$DEST"

    cat > ~/.terraformrc <<EOF
    provider_installation {
      filesystem_mirror {
        path    = "$HOME/tf-mirror"
        include = ["yandex-cloud/yandex"]
      }

      direct {
        exclude = ["yandex-cloud/yandex"]
      }
    }
    EOF
  8) Запускаем terraform
    rm -rf .terraform .terraform.lock.hcl
    terraform init

    terraform plan
    terraform plan -out=tfplan
    terraform apply tfplan

Следующий пункт:
