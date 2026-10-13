# Iceland SEE camera handshake configs

SEE's camera handshake INIT (SNS msg 0x240) loads
`/vendor/lib64/camera/<name>_<slot>.pb` through the FastRPC file
service (adsprpcd).  Stock ships no iceland entries (the stock image
only carries other modules' configs), so attach always failed with
INIT ACK error=1.

These are verbatim copies of same-schema configs from the stock vendor
image, named for the names/slots SEE looks up on this device:

  icelandmain_0.pb  <- vendor/lib64/camera/swangoosefrontmain_3.pb
  icelandfront_1.pb <- vendor/lib64/camera/fairladyfront_3.pb

They are enough for the handshake session to establish (INIT ACK
error=0); actual AON tuning for iceland is not contained in them.

Deployed by linux-firmware-iceland's postinst to /vendor/lib64/camera/
(where adsprpcd serves them to SEE).
