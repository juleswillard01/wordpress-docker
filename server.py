import paramiko
import zipfile
import os
import logging
from dotenv import load_dotenv
from getpass import getpass
from datetime import datetime

# Configurer le logger pour enregistrer dans un fichier avec horodatage
log_dir = "logs"
os.makedirs(log_dir, exist_ok=True)
log_filename = f"{log_dir}/deploy_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

logging.basicConfig(
    filename=log_filename,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
)

# Affichage des logs dans la console
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logging.getLogger().addHandler(console_handler)

# Charger les variables d'environnement depuis xenv/local.env
load_dotenv("xenv/local.env")

# Récupération des informations de connexion et de configuration
HOST = os.getenv("HOST")
ADMIN_USER = os.getenv("ADMIN_USER")
PROJECT_DIRECTORY = os.getenv("PROJECT_DIRECTORY")
REMOTE_DIR = f"/home/{ADMIN_USER}/{PROJECT_DIRECTORY}"
ZIP_NAME = "dist.zip"

# Demande du mot de passe pour l'utilisateur admin
ADMIN_PASSWORD = getpass(f"Entrez le mot de passe pour {ADMIN_USER}@{HOST}: ")

# Fonction pour créer un fichier ZIP contenant tous les fichiers nécessaires pour le déploiement
def create_zip():
    logging.info("Début de la création du fichier ZIP...")
    env_path = 'xenv/dist.env'
    enc_env_path = 'xenv/dist.env.enc'
    password = getpass("Entrez un mot de passe pour chiffrer dist.env: ")
    os.system(f"openssl enc -aes-256-cbc -in {env_path} -out {enc_env_path} -pass pass:{password} -pbkdf2")

    with zipfile.ZipFile(ZIP_NAME, 'w') as zipf:
        files_to_include = [
            'dist/docker-compose-wp.yml',
            'dist/nginx.conf',
            'dist/scripts/install.sh',
            'dist/scripts/admin.sh',
            'dist/scripts/backup.sh',
            'dist/scripts/updateSSL.sh',
            'dist/scripts/logs.sh',
            'dist/scripts/cron-jobs/cron_daily.sh',
            'dist/scripts/cron-jobs/cron_monthly.sh',
            'dist/scripts/cron-jobs/cron_weekly.sh'
        ]

        for file in files_to_include:
            zipf.write(file, arcname=os.path.relpath(file, 'dist'))

        zipf.write(enc_env_path, arcname='dist.env.enc')
        empty_dirs = ['dist/certs', 'dist/volumes', 'dist/logs']
        for dir in empty_dirs:
            zipf.write(dir, arcname=os.path.relpath(dir, 'dist') + '/')

    logging.info("Fichier ZIP créé avec succès.")

# Fonction pour se connecter au serveur via SSH
def create_ssh_client():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, username=ADMIN_USER, password=ADMIN_PASSWORD)
    logging.info("Connexion SSH établie avec succès.")
    return ssh

# Fonction pour transférer le fichier ZIP sur le serveur
def transfer_zip(ssh):
    logging.info("Début du transfert du fichier ZIP vers le serveur...")
    sftp = ssh.open_sftp()
    remote_zip_path = f"{REMOTE_DIR}/{ZIP_NAME}"
    ssh.exec_command(f"mkdir -p {REMOTE_DIR}")
    sftp.put(ZIP_NAME, remote_zip_path)
    sftp.close()
    logging.info("Transfert terminé.")
    return remote_zip_path

# Fonction pour extraire le fichier ZIP sur le serveur
def extract_zip(ssh, remote_zip_path):
    logging.info("Extraction du fichier ZIP sur le serveur...")
    ssh.exec_command(f"unzip -o {remote_zip_path} -d {REMOTE_DIR}")
    ssh.exec_command(f"rm {remote_zip_path}")
    logging.info("Extraction et suppression du fichier ZIP terminées.")

# Fonction pour modifier les permissions d'exécution d'un script sur le serveur
def mod_script(ssh, script_name):
    logging.info(f"Définition des permissions d'exécution pour {script_name} sur le serveur...")
    stdin, stdout, stderr = ssh.exec_command(f"chmod +x {REMOTE_DIR}/{script_name}")
    error = stderr.read().decode().strip()
    if error:
        logging.error(f"Impossible de modifier les permissions pour {script_name}: {error}")
    else:
        logging.info(f"Permissions d'exécution définies pour {script_name}")

# Fonction principale de déploiement
def deploy():
    logging.info("Début du processus de déploiement.")
    create_zip()
    ssh = create_ssh_client()
    try:
        remote_zip_path = transfer_zip(ssh)
        extract_zip(ssh, remote_zip_path)
        for script in ["scripts/install.sh", "scripts/admin.sh", "scripts/logs.sh", "scripts/updateSSL.sh", "scripts/backup.sh"]:
            mod_script(ssh, script)
    finally:
        ssh.close()
        logging.info("Déploiement terminé, connexion SSH fermée.")

if __name__ == "__main__":
    deploy()
