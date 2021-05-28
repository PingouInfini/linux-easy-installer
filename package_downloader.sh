LIB_LIST=(
docker-ce
python3
python3-pip
openjdk-8-jdk
)
for lib in ${LIB_LIST[@]}; do
  echo "#### "+$lib+" ####"

  mkdir -p $lib && cd $lib
  apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-pre-depends $lib | grep "^\w" | sort -u)
  echo ""
  cd ..
done