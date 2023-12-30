# docker build -t 'michelecereda/boinc-client:intel-tw-7.24.1' -f 'intel.opensuse.dockerfile' .
# docker run --rm --name 'boinc' --net='host' --pid='host' \
#   --device '/dev/dri:/dev/dri' -v './data:/var/lib/boinc' \
#   -e BOINC_GUI_RPC_PASSWORD="123" -e BOINC_CMD_LINE_OPTIONS="--allow_remote_gui_rpc" \
#   'michelecereda/boinc-client:intel-tw-7.24.1'

FROM registry.opensuse.org/opensuse/tumbleweed:20231226

LABEL maintainer="michelecereda" \
      description="Intel GPU-savvy BOINC client."

# Global environment settings
ENV BOINC_GUI_RPC_PASSWORD="123" \
    BOINC_REMOTE_HOST="127.0.0.1" \
    BOINC_CMD_LINE_OPTIONS=""

# Copy files
COPY start-boinc.sh /usr/bin/

# Configure
WORKDIR /var/lib/boinc

# BOINC RPC port
EXPOSE 31416

# Install
RUN zypper install -y --no-recommends \
      # Time Zone Database
      timezone=2023c-1.5 \
      # BOINC client
      boinc-client=7.24.1-1.2 \
      # OpenCL ICD Loader
      ocl-icd-devel=2.3.1-2.1 \
      # Intel NEO OpenCL
      intel-opencl=23.22.26516.18-1.2 \
 && zypper clean -a

CMD ["start-boinc.sh"]
