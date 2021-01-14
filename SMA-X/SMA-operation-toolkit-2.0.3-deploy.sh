#### Deploy SMA Operational Toolkit 2.0.3

######## GLOBAL VARIABLES
DR_TOOL_PATH=/opt/smax
DR_BIN_DIR=$DR_TOOL_PATH/toolkit_2.0.3/bin
DR_TMP_DIR=$DR_TOOL_PATH/tmp
DR_OUT_DIR=$DR_TOOL_PATH/output
DR_LOG_DIR=$DR_TOOL_PATH/log


#Prepare Toolpath
sudo mkdir -p $DR_BIN_DIR
sudo mkdir -p $DR_TMP_DIR
sudo mkdir -p $DR_OUT_DIR
sudo mkdir -p $DR_LOG_DIR

#Download the Toolkit
sudo curl -k -g https://owncloud.greenlightgroup.com/index.php/s/C0dQAgVZyeDztqG/download > ./toolkit-2.0.3.zip
sudo unzip ./toolkit-2.0.3.zip

sudo mv ./SMA-operation-toolkit-2.0.3.tar.gz $DR_BIN_DIR/
sudo tar -zxvf $DR_BIN_DIR/SMA-operation-toolkit-2.0.3.tar.gz -C $DR_BIN_DIR/
