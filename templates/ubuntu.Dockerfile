FROM {{ .Image }}

USER root

RUN ARCH="$([ "$(uname -m)" = "x86_64" ] && echo amd64 || echo arm64)"; \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  linux-image-virtual \
  initramfs-tools \
  systemd-sysv \
  systemd \
{{- if .Grub }}
  grub-common \
  grub2-common \
{{- end }}
{{- if .GrubBIOS }}
  grub-pc-bin \
{{- end }}
{{- if .GrubEFI }}
  grub-efi-${ARCH}-bin \
{{- end }}
  dbus \
  isc-dhcp-client \
  iproute2 \
  iputils-ping && \
  find /boot -type l -exec rm {} \;

{{ if gt .Release.VersionID "16.04" }}
RUN systemctl preset-all
{{ end }}

{{ if .Password }}RUN echo "root:{{ .Password }}" | chpasswd {{ end }}

{{- if .Luks }}
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cryptsetup-initramfs && \
    update-initramfs -u -v
{{- end }}

# needs to be after update-initramfs
{{- if not .Grub }}
RUN mv $(ls -t /boot/vmlinuz-* | head -n 1) /boot/vmlinuz && \
      mv $(ls -t /boot/initrd.img-* | head -n 1) /boot/initrd.img
{{- end }}

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*
