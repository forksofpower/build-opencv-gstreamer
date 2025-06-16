#!/usr/bin/env bash

# exit on errors
set -e

# Configuration
NUM_CORES=20

# colors
HIGHLIGHT="\e[34m"
RESET="\e[0m"

# Helpers
print_msg() {
    echo -e "${HIGHLIGHT}$1${RESET}"
}

# NOTE: Assume yay for now but the arguments are the same for pacman
# Update system
print_msg "[System Update]: Start"
yay -Syu
print_msg "[System Update]: Complete"

# Note: Assume uv package manager
# Set up venv for python and install numpy
print_msg "[Python Venv Setup]: Start"
uv venv .opencv-build-env
source .opencv-build-env/bin/activate
uv pip install numpy
print_msg "[Python Venv Setup]: Complete"

# Install build tools and base dependencies
print_msg "[Install Build Tools and Dependencies]: Start"
yay -S base-devel cmake git python-numpy ccache
print_msg "[Install Build Tools and Dependencies]: Complete"

# Install GStreamer and plugins (Base, Good, Bad, Ugly, Libav)
print_msg "[Install OpenCV Dependencies]: Start"
yay -S gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
# Install additional video/GUI libraries (FFmpeg, GTK3, LibDC1394)
yay -S ffmpeg gtk3 libdc1394
print_msg "[Install OpenCV Dependencies]: Complete"

# Clone opencv and opencv_contrib to home folder
# TODO: should be able to build from any folder
print_msg "[Download OpenCV Source]: Start"
cd ~
git clone https://github.com/opencv/opencv.git
git clone https://github.com/opencv/opencv_contrib.git
print_msg "[Download OpenCV Source]: Complete"

# Prepare the build directory
print_msg "[Prepare Build Environment]: Start"
cd ~/opencv
mkdir build
cd build
print_msg "[Prepare Build Environment]: Complete"

# Configure build with gtk2 off
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
sudo make -j$(NUM_CORES)
print_msg "[Configure and Compile OpenCV]: Complete"

# Install OpenCV
print_msg "[Install OpenCV]: Start"
sudo make install
sudo ldconfig
print_msg "[Install OpenCV]: Complete"

# Create pth file to add OpenCV to site-packages
print_msg "[Setup OpenCV Python Path]: Start"
PYTHON_VERSION=$(python3 -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")
echo "/usr/local/lib/python$PYTHON_VERSION/site-packages" > ~/usr/lib/python$PYTHON_VERSION/site-packages/opencv.pth
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

