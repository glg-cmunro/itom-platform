#### Deploy SMA Operational Toolkit 2.0.3

######## GLOBAL VARIABLES
DR_TOOL_PATH=/opt/sma
DR_BIN_DIR=$DR_TOOL_PATH/bin
DR_TMP_DIR=$DR_TOOL_PATH/tmp
DR_OUT_DIR=$DR_TOOL_PATH/output
DR_LOG_DIR=$DR_TOOL_PATH/log


#Prepare Toolpath
mkdir -p $DR_BIN_DIR
mkdir -p $DR_TMP_DIR
mkdir -p $DR_OUT_DIR
mkdir -p $DR_LOG_DIR

#Download the Toolkit
curl -k -g https://owncloud.greenlightgroup.com/index.php/s/C0dQAgVZyeDztqG/download > ./toolkit-2.0.3.zip
unzip ./toolkit-2.0.3.zip

mv ./SMA-operation-toolkit-2.0.3.tar.gz $DR_BIN_DIR/
tar -zxvf $DR_BIN_DIR/SMA-operation-toolkit-2.0.3.tar.gz -C $DR_BIN_DIR/
