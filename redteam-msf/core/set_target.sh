if [ -z "$TARGET" ]; then
  read -p "IP de la machine Metasploitable : " TARGET
  export TARGET
fi
