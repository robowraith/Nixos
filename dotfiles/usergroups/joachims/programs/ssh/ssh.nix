{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      ############
      ############
      ## Privat ##
      ############
      ############

      Host  reason reason_zellij
              User          joachim
              Port          22
              Hostname      192.168.1.111

      Host  server server_zellij
              User          server
              Port          6543
              Hostname      192.168.1.3

      Host  vdr vdr_zellij
              User          joachim
              Port          22
              IdentityFile	~/.ssh/id_rsa
              Hostname      yavdr.fritz.box

      Host  neuromancer neuromancer_zellij nm nm_zellij
              User          jones
              Port          6543
              Hostname	    neuromancer.meine2cent.de

      Host sv08
             User biqu
             Hostname sv08.meine2cent.home
             ForwardAgent yes

      Host  detectorium_bitbucket
              Hostname      bitbucket.org
              User          git
              IdentityFile  ~/.ssh/id_detectorium_ed25519
              IdentitiesOnly yes

      ############
      ############
      ## Arbeit ##
      ############
      ############

      #############
      # Webserver #
      #############

      Host  ws1 ws1_zellij ws1_deploy
              Hostname      ws1.42he.com
              #HostName	     81.95.13.180

      Host  ws2 ws2_zellij ws2_deploy
              Hostname    	ws2.42he.com
              #HostName   	 81.95.13.181

      Host  ass ass_tumx ass_deploy
              Hostname    	ass.42he.com
              #Hostname	     80.255.12.189

      Host  ws9 ws9_zellij ws9_deploy ws9_rescue
              Hostname      ws9.42he.com
              #HostName	     138.201.196.231

      ###################
      # Datenbankserver #
      ###################

      Host  dba dba_zellij storage1 storage1_zellij
              Hostname      dba.42he.com
              #Hostname     ^80.255.12.186

      Host  dbb dbb_zellij storage2 storage2_zellij
              Hostname      dbb.42he.com
              #Hostname      80.255.12.187

      Host  dbc dbc_zellij storage3 storage3_zellij
              Hostname      dbc.42he.com
              #Hostname      80.255.12.188

      ##################
      # Utility-Server #
      ##################

      Host  dev1 dev1_zellij dev1_rescue
              Hostname      dev1.42he.com
              #Hostname      5.9.123.81

      Host  db1 db1_zellij
              Hostname      db1.42he.com
              #Hostname      81.95.13.182

      Host  db2 db2_zellij
              Hostname      db2.42he.com
              #Hostname      81.95.13.183

      Host storage4 storage4_zellij storage4_rescue st4 st4_zellij st4_rescue
           Hostname       storage4.42he.com
           #Hostname       195.201.193.174

      ###############
      # Mail-Server #
      ###############

      Host mail1 mail1_zellij
           Hostname mail1.42he.com
           #Hostnam 188.245.219.216

      Host mail2 mail2_zellij
           Hostname mail2.42he.com
           #Hostnam 162.55.61.28


      #################
      # Backup Server #
      #################

      Host  sx1 sx1_zellij sx1_rescue
              Hostname      sx1.42he.com
              #Hostname      195.201.192.241

      #################
      # Andere Server #
      #################

      Host  gr1 gr1_zellij
            Hostname      gr1.42he.com
            #Hostname      95.216.147.168

      ####################
      # Juniper Switches #
      ####################

      #  Host  juniper
      #  	    User          root
      #      	Hostname      81.95.13.178

      #####################
      # Kubernetes-Server #
      #####################

      # Application Cluster
      Host  k1 k1_zellij k1_rescue
              Hostname      k1.42he.com
              #Hostname      81.95.3.178

      Host  k2 k2_zellij k2_rescue
              Hostname      k2.42he.com
              #Hostname      81.95.3.179

      Host  k3 k3_zellij k3_rescue
              Hostname      k3.42he.com
              #Hostname      81.95.3.180

      Host  k4 k4_zellij k4_rescue
            Hostname      k4.42he.com
            #Hostname      81.95.3.181

      Host  ac1 ac1_zellij ac1_rescue
              Hostname      ac1.42he.com
              #Hostname      81.95.3.178

      Host  ac2 ac2_zellij ac2_rescue
              Hostname      ac2.42he.com
              #Hostname      81.95.3.179

      Host  ac3 ac3_zellij ac3_rescue
              Hostname      ac3.42he.com
              #Hostname      81.95.3.180

      Host  ac4 ac4_zellij ac4_rescue
              Hostname      ac4.42he.com
            #Hostname      81.95.3.181

      # Development Cluster
      Host  dc1 dc1_zellij dc1_rescue
              Hostname      dc1.42he.com
              #Hostname      65.108.237.109

      Host  dc2 dc2_zellij dc2_rescue
              Hostname      dc2.42he.com
              #Hostname      65.108.199.207

      Host  dc3 dc3_zellij dc3_rescue
              Hostname      dc3.42he.com
              #Hostname      65.21.44.253

      # Marketing Pages Cluster
      Host  ws7 ws7_zellij ws7_rescue
            Hostname     ws7.42he.com

      ##########
      # Tunnel #
      ##########

      Host  tunnel_*
            SessionType   none
            ControlMaster auto
            ControlPath   /tmp/ssh_socket_%k

      Host  tunnel_haproxy_dba
              Hostname      dba.42he.com
              LocalForward  8081 localhost:8080

      Host  tunnel_haproxy_dbb
              Hostname      dbb.42he.com
              LocalForward  8082 localhost:8080

      Host  tunnel_haproxy_dbc
              Hostname      dbc.42he.com
              LocalForward  8083 localhost:8080

      Host  tunnel_k8s_production_cluster
              Hostname      ac4.42he.com
              LocalForward  64430 localhost:6443

      Host  tunnel_k8s_development_cluster
              Hostname      dc1.42he.com
              LocalForward  64431 localhost:6443

      Host  tunnel_k8s_vagrant_apps_cluster
            Hostname      ac1.local
            User          vagrant
            LocalForward  64438 localhost:6443
            StrictHostKeyChecking no
            IdentityFile  ~/code/ansible/vagrant/.vagrant/machines/ac1/libvirt/private_key

      Host  tunnel_mysql_dba
              Hostname      dbb.42he.com
              LocalForward  33306 10.10.0.201:3306

      Host  tunnel_mysql_dba_local
              Hostname      dba.42he.com
              LocalForward  33306 127.0.0.1:3306

      Host  tunnel_puma_ass
            Hostname      ass.42he.com
            LocalForward  4443 10.10.0.12:443

      Host  tunnel_kibana_dbc
            Hostname      dbc.42he.com
            LocalForward  5601 10.10.0.203:5601

      Host  tunnel_minio1_dba tunnel_minio1_storage1
              Hostname      dba.42he.com
              LocalForward  9001 localhost:9001

      Host  tunnel_minio2_dbb tunnel_minio2_storage2
              Hostname      dbb.42he.com
            LocalForward  9002 localhost:9001

      Host  tunnel_minio3_dbc tunnel_minio3_storage3
              Hostname      dbc.42he.com
              LocalForward  9003 localhost:9001

      Host  tunnel_minio_mirror_storage4
              Hostname      storage4.42he.com
              LocalForward  9004 localhost:9001

      Host  tunnel_minio_backup_sx1
              Hostname      sx1.42he.com
              LocalForward  9005 localhost:9001

      Host  tunnel_chronograf_db1
              Hostname      db1.42he.com
              LocalForward  3333 localhost:3333

      ########
      # IPMI #
      ########

      Host  ipmi_*
            IdentityFile  ~/.ssh/id_ed25519
            SessionType   none
            ControlMaster auto
            ControlPath   /tmp/ssh_socket_%k

      Host  ipmi_all_socks
            DynamicForward 1337

      Host  ipmi_db1
            Hostname      ass.42he.com
            # LocalForward  8000 10.10.10.100:80
            LocalForward  4430 10.10.10.100:443
            LocalForward  5900 10.10.10.100:5900

      Host  ipmi_db2
            Hostname      ass.42he.com
            # LocalForward  8001 10.10.10.101:80
            LocalForward  4431 10.10.10.101:443
            LocalForward  5900 10.10.10.101:5900

      Host  ipmi_ws1
            Hostname      ass.42he.com
            # LocalForward  8002 10.10.10.102:80
            LocalForward  4432 10.10.10.102:443
            LocalForward  5900 10.10.10.102:5900

      Host  ipmi_ws2
            Hostname      ass.42he.com
            # LocalForward  8003 10.10.10.103:80
            LocalForward  4433 10.10.10.103:443
            LocalForward  5900 10.10.10.103:5900

      Host  ipmi_dba
            Hostname      ass.42he.com
            # LocalForward  8004 10.10.10.104:80
            LocalForward  4434 10.10.10.104:443
            LocalForward  5900 10.10.10.104:5900

      Host  ipmi_dbb
            Hostname      ass.42he.com
            # LocalForward  8005 10.10.10.105:80
            LocalForward  4435 10.10.10.105:443
            LocalForward  5900 10.10.10.105:5900

      Host  ipmi_dbc
            Hostname      ass.42he.com
            # LocalForward  8006 10.10.10.106:80
            LocalForward  4436 10.10.10.106:443
            LocalForward  5900 10.10.10.106:5900

      Host  ipmi_ass
            Hostname      ws1.42he.com
            # LocalForward  8007 10.10.10.107:80
            LocalForward  4437 10.10.10.107:443
            LocalForward  5900 10.10.10.107:5900

      Host  ipmi_ac1
            Hostname      db2.42he.com
            # LocalForward  8010 10.10.10.110:80
            LocalForward  4440 10.10.10.110:443
            LocalForward  5900 10.10.10.110:5900

      Host  ipmi_ac2
            Hostname      db2.42he.com
            # LocalForward  8011 10.10.10.111:80
            LocalForward  4441 10.10.10.111:443
            LocalForward  5900 10.10.10.111:5900

      Host  ipmi_ac3
            Hostname      db2.42he.com
            # LocalForward  8012 10.10.10.112:80
            LocalForward  4442 10.10.10.112:443
            LocalForward  5900 10.10.10.112:5900

      Host  ipmi_ac4
            Hostname      db2.42he.com
            # LocalForward  8012 10.10.10.113:80
            LocalForward  4442 10.10.10.113:443
            LocalForward  5900 10.10.10.113:5900

      #######################
      # Virtuelle Maschinen #
      #######################

      Host ac1_local
          Hostname ac1.local
          # Hostname 192.168.56.20"

      Host ac2_local
          Hostname ac2.local
          # Hostname 192.168.56.21"

      Host ac3_local
          Hostname ac3.local
          # Hostname 192.168.56.22"

      Host ac4_local
          Hostname ac4.local
          # Hostname 192.168.56.23"

      Host ass_local
          Hostname ass.local
          # Hostname 192.168.56.24"

      Host db1_local
          Hostname db1.local
          # Hostname 192.168.56.25"

      Host db2_local
          Hostname db2.local
          # Hostname 192.168.56.26"

      Host dba_local
          Hostname dba.local
          # Hostname 192.168.56.27"

      Host dbb_local
          Hostname dbb.local
          # Hostname 192.168.56.28"

      Host dbc_local
          Hostname dbc.local
          # Hostname 192.168.56.29"

      Host dc1_local
          Hostname dc1.local
          # Hostname 192.168.56.30"

      Host dc2_local
          Hostname dc2.local
          # Hostname 192.168.56.31"

      Host dc3_local
          Hostname dc3.local
          # Hostname 192.168.56.32"

      Host dev1_local
          Hostname dev1.local
          # Hostname :192.168.56.33"

      Host gr1_local
          Hostname gr1.local
          # Hostname 192.168.56.34"

      Host mail1_local
          Hostname mail1.local
          # Hostname l:192.168.56.35"

      Host mail2_local
          Hostname mail2.local
          # Hostname l:192.168.56.36"

      Host sx1_local
          Hostname sx1.local
          # Hostname 192.168.56.37"

      Host ws1_local
          Hostname ws1.local
          # Hostname 192.168.56.38"

      Host ws2_local
          Hostname ws2.local
          # Hostname 192.168..56.39"

      Host ws9_local
          Hostname ws9.local
          # Hostname 192.168.56.40"

      ######################
      # Generelle Optionen #
      ######################

      Host  *_local
            StrictHostKeyChecking no

      Host  *_zellij
            RemoteCommand zellij attach || zellij -s %n
            RequestTTY    yes

      Host  *_deploy
            User          deploy

      Host  *_rescue
            User          jollymaeh
    '';
    enableDefaultConfig = false;
    matchBlocks."*" = {
      user = "joachim";
      port = 22;
    };
  };
}
