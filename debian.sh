#!/usr/bin/env bash

# exit on errors
set -e
source ./utils.sh

# Configuration
NUM_CORES=20

# Update system
print_msg "[System Update]: Start"
sudo apt update
sudo apt upgrade -y
print_msg "[System Update]: Complete"

# Set up venv for python and install numpy
# Note: Using uv as requested in template
print_msg "[Python Venv Setup]: Start"
# Ensure uv is installed (comment out if you already have it)
# curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv .opencv-build-env
source .opencv-build-env/bin/activate
uv pip install numpy
print_msg "[Python Venv Setup]: Complete"

# Install build tools and base dependencies
print_msg "[Install Build Tools and Dependencies]: Start"
sudo apt install -y build-essential cmake git python3-numpy ccache pkg-config
print_msg "[Install Build Tools and Dependencies]: Complete"

# Install GStreamer and plugins (From the article's list)
print_msg "[Install OpenCV Dependencies]: Start"
sudo apt install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc \
    gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 gstreamer1.0-pulseaudio

# Install GStreamer Dev libraries
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# Install Codec libraries
# Note: libavresample-dev is deprecated in newer Ubuntu versions (20.04+). 
# If this fails, remove 'libavresample-dev' from the list below.
sudo apt install -y libavcodec-dev libavformat-dev libavutil-dev libswscale-dev # libavresample-dev

# Install GTK3 and Camera support
sudo apt install -y libgtk-3-dev libdc1394-22-dev
print_msg "[Install OpenCV Dependencies]: Complete"

# Clone opencv and opencv_contrib to home folder
print_msg "[Download OpenCV Source]: Start"
cd ~
# Check if directories exist to avoid git errors
if [ ! -d "opencv" ]; then
    git clone https://github.com/opencv/opencv.git
fi
if [ ! -d "opencv_contrib" ]; then
    git clone https://github.com/opencv/opencv_contrib.git
fi
print_msg "[Download OpenCV Source]: Complete"

# Prepare the build directory
print_msg "[Prepare Build Environment]: Start"
cd ~/opencv
mkdir -p build
cd build
print_msg "[Prepare Build Environment]: Complete"

# Configure build
# Note: Debian usually puts python packages in dist-packages, but we install to /usr/local
print_msg "[Configure and Compile OpenCV]: Start"
cmake -D CMAKE_BUILD_TYPE=Release \
-D CMAKE_INSTALL_PREFIX=/usr/local \
-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
-D WITH_GSTREAMER=ON \
-D WITH_GTK=ON \
-D WITH_GTK_2_X=OFF \
-D WITH_FFMPEG=ON \
-D WITH_1394=ON \
-D BUILD_opencv_python3=ON \
-D OPENCV_GENERATE_PKGCONFIG=ON \
..

# Compile source
# Fixed: removed the $() around NUM_CORES variables for correct bash usage
echo "Building with $NUM_CORES cores..."
sudo make -j$NUM_CORES
print_msg "[Configure and Compile OpenCV]: Complete"

# Install OpenCV
print_msg "[Install OpenCV]: Start"
sudo make install
sudo ldconfig
print_msg "[Install OpenCV]: Complete"

# Create pth file to add OpenCV to dist-packages
# Debian/Ubuntu uses 'dist-packages' for system python, not 'site-packages'
print_msg "[Setup OpenCV Python Path]: Start"
PYTHON_VERSION=$(python3 -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")
LOCAL_PACKAGES_PATH="/usr/local/lib/python$PYTHON_VERSION/site-packages"
SYSTEM_PACKAGES_PATH="/usr/lib/python3/dist-packages"

# We write the .pth file into the system dist-packages so python finds the /usr/local libs
echo "$LOCAL_PACKAGES_PATH" | sudo tee "$SYSTEM_PACKAGES_PATH/opencv.pth" > /dev/null
print_msg "[Setup OpenCV Python Path]: Complete"

# Verify installation
print_msg "[Verify OpenCV Installation]: Start"
python3 -c "import cv2; print('OpenCV version:', cv2.__version__)"
print_msg "[Verify OpenCV Installation]: Complete"

# Deactivate venv
print_msg "[Cleanup]: Start"
cd ~
deactivate
rm -rf ~/.opencv-build-env
print_msg "[Cleanup]: Complete"

print_msg "[OpenCV Installation Completed Successfully]"