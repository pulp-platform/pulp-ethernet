// Generated register defines for eth_idma

#ifndef _ETH_IDMA_REG_DEFS_
#define _ETH_IDMA_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define ETH_IDMA_PARAM_REG_WIDTH 32

// lower 4 bytes of the devices MAC address
#define ETH_IDMA_LOW_ADDR_REG_OFFSET 0x0

// upper 2 bytes of the devices MAC address, cooked, loopback, promiscuous
// flag, irq_en
#define ETH_IDMA_MACHI_REG_OFFSET 0x4
#define ETH_IDMA_MACHI_UPPER_ADDR_MASK 0xffff
#define ETH_IDMA_MACHI_UPPER_ADDR_OFFSET 0
#define ETH_IDMA_MACHI_UPPER_ADDR_FIELD \
  ((bitfield_field32_t) { .mask = ETH_IDMA_MACHI_UPPER_ADDR_MASK, .index = ETH_IDMA_MACHI_UPPER_ADDR_OFFSET })
#define ETH_IDMA_MACHI_COOKED_BIT 16
#define ETH_IDMA_MACHI_LOOPBACK_BIT 17
#define ETH_IDMA_MACHI_SPARE_MASK 0xf
#define ETH_IDMA_MACHI_SPARE_OFFSET 18
#define ETH_IDMA_MACHI_SPARE_FIELD \
  ((bitfield_field32_t) { .mask = ETH_IDMA_MACHI_SPARE_MASK, .index = ETH_IDMA_MACHI_SPARE_OFFSET })
#define ETH_IDMA_MACHI_PROMISCUOUS_BIT 22
#define ETH_IDMA_MACHI_IRQ_EN_BIT 23

// mdio control register
#define ETH_IDMA_MDIO_REG_OFFSET 0x8
#define ETH_IDMA_MDIO_MDIO_CLK_BIT 0
#define ETH_IDMA_MDIO_MDIO_O_BIT 1
#define ETH_IDMA_MDIO_MDIO_OE_BIT 2
#define ETH_IDMA_MDIO_MDIO_I_BIT 3

// TX busy
#define ETH_IDMA_TX_BUSY_REG_OFFSET 0xc
#define ETH_IDMA_TX_BUSY_TX_BUSY_BIT 0

// TX frame check register
#define ETH_IDMA_TX_FCS_REG_OFFSET 0x10

// RX frame check register
#define ETH_IDMA_RX_FCS_REG_OFFSET 0x14

// receive status register
#define ETH_IDMA_RSR_REG_OFFSET 0x18
#define ETH_IDMA_RSR_RX_COMPLETE_BIT 0
#define ETH_IDMA_RSR_RX_IRQ_BIT 1

// Low source address
#define ETH_IDMA_SRC_ADDR_LOW_REG_OFFSET 0x1c

// High source address
#define ETH_IDMA_SRC_ADDR_HIGH_REG_OFFSET 0x20

// Low destination address
#define ETH_IDMA_DST_ADDR_LOW_REG_OFFSET 0x24

// High destination address
#define ETH_IDMA_DST_ADDR_HIGH_REG_OFFSET 0x28

// Low transfer length in byte
#define ETH_IDMA_LENGTH_LOW_REG_OFFSET 0x2c

// High transfer length in byte
#define ETH_IDMA_LENGTH_HIGH_REG_OFFSET 0x30

// Configuration Register for DMA settings
#define ETH_IDMA_CONF_REG_OFFSET 0x34
#define ETH_IDMA_CONF_DECOUPLE_AW_BIT 0
#define ETH_IDMA_CONF_DECOUPLE_RW_BIT 1
#define ETH_IDMA_CONF_SRC_REDUCE_LEN_BIT 2
#define ETH_IDMA_CONF_DST_REDUCE_LEN_BIT 3
#define ETH_IDMA_CONF_SRC_MAX_LLEN_MASK 0x7
#define ETH_IDMA_CONF_SRC_MAX_LLEN_OFFSET 4
#define ETH_IDMA_CONF_SRC_MAX_LLEN_FIELD \
  ((bitfield_field32_t) { .mask = ETH_IDMA_CONF_SRC_MAX_LLEN_MASK, .index = ETH_IDMA_CONF_SRC_MAX_LLEN_OFFSET })
#define ETH_IDMA_CONF_DST_MAX_LLEN_MASK 0x7
#define ETH_IDMA_CONF_DST_MAX_LLEN_OFFSET 7
#define ETH_IDMA_CONF_DST_MAX_LLEN_FIELD \
  ((bitfield_field32_t) { .mask = ETH_IDMA_CONF_DST_MAX_LLEN_MASK, .index = ETH_IDMA_CONF_DST_MAX_LLEN_OFFSET })
#define ETH_IDMA_CONF_ENABLE_ND_BIT 10
#define ETH_IDMA_CONF_SRC_PROTOCOL_MASK 0x7
#define ETH_IDMA_CONF_SRC_PROTOCOL_OFFSET 11
#define ETH_IDMA_CONF_SRC_PROTOCOL_FIELD \
  ((bitfield_field32_t) { .mask = ETH_IDMA_CONF_SRC_PROTOCOL_MASK, .index = ETH_IDMA_CONF_SRC_PROTOCOL_OFFSET })
#define ETH_IDMA_CONF_DST_PROTOCOL_MASK 0x7
#define ETH_IDMA_CONF_DST_PROTOCOL_OFFSET 14
#define ETH_IDMA_CONF_DST_PROTOCOL_FIELD \
  ((bitfield_field32_t) { .mask = ETH_IDMA_CONF_DST_PROTOCOL_MASK, .index = ETH_IDMA_CONF_DST_PROTOCOL_OFFSET })

// idma request valid
#define ETH_IDMA_REQ_VALID_REG_OFFSET 0x38
#define ETH_IDMA_REQ_VALID_REQ_VALID_BIT 0

// idma request ready
#define ETH_IDMA_REQ_READY_REG_OFFSET 0x3c
#define ETH_IDMA_REQ_READY_REQ_READY_BIT 0

// idma response ready
#define ETH_IDMA_RSP_READY_REG_OFFSET 0x40
#define ETH_IDMA_RSP_READY_RSP_READY_BIT 0

// idma response valid
#define ETH_IDMA_RSP_VALID_REG_OFFSET 0x44
#define ETH_IDMA_RSP_VALID_RSP_VALID_BIT 0

// to clear reception completes
#define ETH_IDMA_RX_END_CLR_REG_OFFSET 0x48
#define ETH_IDMA_RX_END_CLR_RX_END_CLR_BIT 0

// for sw to clear rsp_valid once read
#define ETH_IDMA_RSP_VALID_CLR_REG_OFFSET 0x4c
#define ETH_IDMA_RSP_VALID_CLR_RSP_VALID_CLR_BIT 0

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _ETH_IDMA_REG_DEFS_
// End generated register defines for eth_idma