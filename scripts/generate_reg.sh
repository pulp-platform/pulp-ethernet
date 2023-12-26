utils/reggen/regtool.py -r -t rtl/eth_idma_reg  eth_idma_reg.hjson
utils/reggen/regtool.py -D -o driver/eth_idma_reg/eth_idma_reg.h  eth_idma_reg.hjson
#.bender/git/checkouts/register_interface-55d4a861c0a3a573/vendor/lowrisc_opentitan/util/regtool.py -s -t dv eth_framing.hjson
