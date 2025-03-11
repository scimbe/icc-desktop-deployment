# Empfehlungen für entwicklungsspezifische Tools im ICC Desktop

Diese Dokumentation bietet Empfehlungen für zusätzliche Entwicklungstools, die im ICC debian XFCE Desktop installiert werden können, sowie Konfigurationshinweise für verschiedene Entwicklungsszenarien.

## Inhaltsverzeichnis

1. [Webentwicklung](#webentwicklung)
2. [Java-Entwicklung](#java-entwicklung)
3. [Python-Entwicklung](#python-entwicklung)
4. [DevOps und Systemadministration](#devops-und-systemadministration)
5. [Datenbankentwicklung](#datenbankentwicklung)
6. [Generelle Entwicklungstools](#generelle-entwicklungstools)
7. [IDE-Erweiterungen und Plugins](#ide-erweiterungen-und-plugins)

## Webentwicklung

### Frontend-Entwicklung

1. **Node.js und NPM:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
   sudo apt-get install -y nodejs
   
   # Überprüfen der Installation
   node -v
   npm -v
   ```

2. **Yarn (Alternative zu NPM):**
   ```bash
   curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
   echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
   sudo apt-get update && sudo apt-get install yarn
   ```

3. **Frontend-Frameworks und Tools:**
   ```bash
   # Angular CLI
   npm install -g @angular/cli
   
   # Vue CLI
   npm install -g @vue/cli
   
   # Create React App
   npm install -g create-react-app
   
   # Vite
   npm install -g vite
   ```

### Backend-Entwicklung

1. **PHP und Composer:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
   
   # Composer Installation
   curl -sS https://getcomposer.org/installer | php
   sudo mv composer.phar /usr/local/bin/composer
   sudo chmod +x /usr/local/bin/composer
   ```

2. **Ruby on Rails:**
   ```bash
   sudo apt-get install -y ruby-full ruby-railties
   
   # Oder via RVM für bessere Versionsverwaltung
   curl -sSL https://get.rvm.io | bash -s stable
   source ~/.rvm/scripts/rvm
   rvm install 3.0.0
   gem install rails
   ```

## Java-Entwicklung

1. **JDK (OpenJDK):**
   ```bash
   sudo apt-get update
   sudo apt-get install -y openjdk-17-jdk
   
   # Prüfen der Java-Version
   java -version
   javac -version
   ```

2. **Build-Tools:**
   ```bash
   # Maven
   sudo apt-get install -y maven
   
   # Gradle
   sudo apt-get install -y gradle
   ```

3. **Spring Boot CLI:**
   ```bash
   # Via SDKMAN
   curl -s "https://get.sdkman.io" | bash
   source "$HOME/.sdkman/bin/sdkman-init.sh"
   sdk install springboot
   ```

4. **Eclipse:**
   ```bash
   # Eclipse-Paket herunterladen und entpacken
   wget https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2022-03/R/eclipse-java-2022-03-R-linux-gtk-x86_64.tar.gz -O eclipse.tar.gz
   tar -xzf eclipse.tar.gz -C ~/
   
   # Desktop-Verknüpfung erstellen
   echo "[Desktop Entry]
   Name=Eclipse
   Type=Application
   Exec=$HOME/eclipse/eclipse
   Terminal=false
   Icon=$HOME/eclipse/icon.xpm
   Comment=Eclipse IDE
   NoDisplay=false
   Categories=Development;IDE;
   Name[en]=Eclipse" > ~/Desktop/eclipse.desktop
   chmod +x ~/Desktop/eclipse.desktop
   ```

## Python-Entwicklung

1. **Python und grundlegende Tools:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y python3 python3-pip python3-venv
   
   # Standard-Tools
   pip3 install ipython pytest flake8 black mypy
   ```

2. **Virtuelle Umgebungen mit Poetry:**
   ```bash
   curl -sSL https://install.python-poetry.org | python3 -
   
   # Poetry zu PATH hinzufügen
   echo 'export PATH="$HOME/.poetry/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Jupyter Notebook:**
   ```bash
   pip3 install notebook
   
   # Starten mit
   jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser
   
   # Dann im Browser: http://localhost:8888 (nach Port-Forwarding)
   ```

4. **PyCharm Community Edition:**
   ```bash
   sudo snap install pycharm-community --classic
   ```

## DevOps und Systemadministration

1. **Docker:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg lsb-release
   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io
   
   # Benutzer zur Docker-Gruppe hinzufügen
   sudo usermod -aG docker abc
   ```

2. **Kubernetes-Tools:**
   ```bash
   # kubectl ist bereits in der ICC-Umgebung vorhanden
   
   # Helm
   curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
   echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
   sudo apt-get update
   sudo apt-get install -y helm
   
   # k9s (Kubernetes CLI Tool)
   curl -sS https://webinstall.dev/k9s | bash
   ```

3. **Terraform:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y gnupg software-properties-common
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update
   sudo apt-get install -y terraform
   ```

## Datenbankentwicklung

1. **PostgreSQL-Client und Tools:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y postgresql-client pgadmin4
   ```

2. **MySQL/MariaDB-Client und Tools:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y mysql-client
   
   # MySQL Workbench
   sudo apt-get install -y mysql-workbench
   ```

3. **MongoDB-Tools:**
   ```bash
   # MongoDB Shell
   wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
   echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
   sudo apt-get update
   sudo apt-get install -y mongodb-org-shell
   
   # MongoDB Compass
   wget https://downloads.mongodb.com/compass/mongodb-compass_1.31.0_amd64.deb
   sudo dpkg -i mongodb-compass_1.31.0_amd64.deb
   ```

4. **DBeaver (universeller Datenbank-Client):**
   ```bash
   wget -O ~/Downloads/dbeaver.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
   sudo dpkg -i ~/Downloads/dbeaver.deb
   sudo apt-get install -f
   ```

## Generelle Entwicklungstools

1. **Git-Erweiterungen:**
   ```bash
   # Git LFS
   sudo apt-get install -y git-lfs
   git lfs install
   
   # GitKraken
   wget https://release.gitkraken.com/linux/gitkraken-amd64.deb
   sudo dpkg -i gitkraken-amd64.deb
   sudo apt-get install -f
   ```

2. **Diff- und Merge-Tools:**
   ```bash
   sudo apt-get install -y meld
   ```

3. **API-Entwicklungs- und Testtools:**
   ```bash
   # Postman
   wget https://dl.pstmn.io/download/latest/linux64 -O postman.tar.gz
   sudo tar -xzf postman.tar.gz -C /opt
   sudo ln -s /opt/Postman/Postman /usr/bin/postman
   
   # Insomnia (Alternative)
   echo "deb [trusted=yes arch=amd64] https://download.konghq.com/insomnia-ubuntu/ default all" | sudo tee -a /etc/apt/sources.list.d/insomnia.list
   sudo apt-get update
   sudo apt-get install -y insomnia
   ```

4. **Dokumentationstools:**
   ```bash
   # Markdown-Editoren
   sudo apt-get install -y remarkable
   
   # PlantUML
   sudo apt-get install -y plantuml
   ```

## IDE-Erweiterungen und Plugins

### VS Code Erweiterungen

1. **Allgemeine Erweiterungen:**
   ```bash
   code --install-extension ms-vscode.vscode-typescript-next
   code --install-extension dbaeumer.vscode-eslint
   code --install-extension esbenp.prettier-vscode
   code --install-extension ms-azuretools.vscode-docker
   code --install-extension ms-vscode-remote.remote-ssh
   code --install-extension eamodio.gitlens
   code --install-extension streetsidesoftware.code-spell-checker
   code --install-extension yzhang.markdown-all-in-one
   ```

2. **Sprachspezifische Erweiterungen:**
   ```bash
   # Python
   code --install-extension ms-python.python
   code --install-extension ms-python.vscode-pylance
   
   # Java
   code --install-extension vscjava.vscode-java-pack
   
   # JavaScript/TypeScript
   code --install-extension ms-vscode.vscode-typescript-next
   code --install-extension dbaeumer.vscode-eslint
   
   # C/C++
   code --install-extension ms-vscode.cpptools
   
   # Go
   code --install-extension golang.go
   
   # Rust
   code --install-extension rust-lang.rust-analyzer
   ```

### Sublime Text Packages

1. **Package Control installieren:**
   ```
   Öffnen Sie Sublime Text und drücken Sie Ctrl+` (Backtick), um die Konsole zu öffnen.
   Fügen Sie folgenden Code ein und drücken Sie Enter:
   ```

   ```python
   import urllib.request,os,hashlib; h = '2915d1851351e5ee549c20394736b442' + '8bc59f460fa1548d1514676163dafc88'; pf = 'Package Control.sublime-package'; ipp = sublime.installed_packages_path(); urllib.request.install_opener( urllib.request.build_opener( urllib.request.ProxyHandler()) ); by = urllib.request.urlopen( 'http://packagecontrol.io/' + pf.replace(' ', '%20')).read(); dh = hashlib.sha256(by).hexdigest(); print('Error validating download (got %s instead of %s), please try manual install' % (dh, h)) if dh != h else open(os.path.join( ipp, pf), 'wb' ).write(by)
   ```

2. **Empfohlene Packages installieren:**
   - Öffnen Sie Sublime Text
   - Drücken Sie Ctrl+Shift+P
   - Geben Sie "Package Control: Install Package" ein und drücken Sie Enter
   - Installieren Sie diese Packages einzeln:
     - SublimeLinter
     - SublimeLinter-flake8
     - SublimeLinter-eslint
     - Emmet
     - GitGutter
     - SideBarEnhancements
     - Theme - Monokai Pro
     - A File Icon

### Eclipse-Plugins

Die Installation von Eclipse-Plugins erfolgt am besten über den Eclipse Marketplace:

1. Öffnen Sie Eclipse
2. Gehen Sie zu Help > Eclipse Marketplace
3. Suchen und installieren Sie folgende Plugins:
   - SpringTools 4
   - EGit - Git Integration for Eclipse
   - Maven Integration for Eclipse
   - Eclipse Web Developer Tools
   - Checkstyle
   - SonarLint

Diese Dokumentation bietet einen Überblick über empfohlene Entwicklungstools für verschiedene Szenarien. Je nach spezifischem Projekt können weitere oder andere Tools erforderlich sein.
