// Generated register defines for eth_framing

#ifndef _ETH_FRAMING_REG_DEFS_
#define _ETH_FRAMING_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define ETH_FRAMING_PARAM_REG_WIDTH 32

// Configures the lower 4 bytes of the devices MAC address
#define ETH_FRAMING_CONFIG0_REG_OFFSET 0x0

// Configures the: upper 2 bytes of the devices MAC address, promiscuous
// flag, MDIO interface
#define ETH_FRAMING_CONFIG1_REG_OFFSET 0x4
#define ETH_FRAMING_CONFIG1_UPPER_MAC_ADDRESS_MASK 0xffff
#define ETH_FRAMING_CONFIG1_UPPER_MAC_ADDRESS_OFFSET 0
#define ETH_FRAMING_CONFIG1_UPPER_MAC_ADDRESS_FIELD \
  ((bitfield_field32_t) { .mask = ETH_FRAMING_CONFIG1_UPPER_MAC_ADDRESS_MASK, .index = ETH_FRAMING_CONFIG1_UPPER_MAC_ADDRESS_OFFSET })
#define ETH_FRAMING_CONFIG1_PROMISCUOUS_BIT 16
#define ETH_FRAMING_CONFIG1_PHY_MDCLK_BIT 17
#define ETH_FRAMING_CONFIG1_PHY_MDIO_O_BIT 18
#define ETH_FRAMING_CONFIG1_PHY_MDIO_OE_BIT 19

// The FCS TX status
#define ETH_FRAMING_CONFIG2_REG_OFFSET 0x8

// The FCS RX status
#define ETH_FRAMING_CONFIG3_REG_OFFSET 0xc

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _ETH_FRAMING_REG_DEFS_
// End generated register defines for eth_framing