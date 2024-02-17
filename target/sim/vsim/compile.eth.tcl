# This script was generated automatically by bender.
set ROOT "/scratch/chaol/git_test/feb_16_idma_fix/fe-ethernet"

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/clk_rst_gen.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/rand_id_queue.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/rand_stream_mst.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/rand_synch_holdable_driver.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/rand_verif_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/signal_highlighter.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/sim_timeout.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/stream_watchdog.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/rand_synch_driver.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/src/rand_stream_slv.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/common_verification-8c4525ffeb875371/test/tb_clk_rst_gen.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/rtl/tc_sram.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/rtl/tc_sram_impl.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/rtl/tc_clk.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/cluster_pwr_cells.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/generic_memory.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/generic_rom.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/pad_functional.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/pulp_buffer.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/pulp_pwr_cells.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/tc_pwr.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/test/tb_tc_sram.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/pulp_clock_gating_async.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/cluster_clk_cells.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-5426a8fa066d6fdb/src/deprecated/pulp_clk_cells.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/binary_to_gray.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cb_filter_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cc_onehot.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_reset_ctrlr_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cf_math_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/clk_int_div.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/delta_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/ecc_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/edge_propagator_tx.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/exp_backoff.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/fifo_v3.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/gray_to_binary.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/isochronous_4phase_handshake.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/isochronous_spill_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/lfsr.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/lfsr_16bit.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/lfsr_8bit.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/lossy_valid_to_stream.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/mv_filter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/onehot_to_bin.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/plru_tree.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/popcount.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/rr_arb_tree.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/rstgen_bypass.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/serial_deglitch.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/shift_reg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/shift_reg_gated.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/spill_register_flushable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_demux.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_filter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_fork.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_intf.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_join_dynamic.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_mux.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_throttle.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/sub_per_hash.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/sync.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/sync_wedge.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/unread.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/read.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/addr_decode_dync.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_2phase.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_4phase.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/clk_int_div_static.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/addr_decode.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/addr_decode_napot.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/multiaddr_decode.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cb_filter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_fifo_2phase.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/clk_mux_glitch_free.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/ecc_decode.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/ecc_encode.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/edge_detect.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/lzc.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/max_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/rstgen.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/spill_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_delay.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_fifo.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_fork_dynamic.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_join.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_reset_ctrlr.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_fifo_gray.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/fall_through_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/id_queue.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_to_mem.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_arbiter_flushable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_fifo_optimal_wrap.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_xbar.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_fifo_gray_clearable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/cdc_2phase_clearable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/mem_to_banks_detailed.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_arbiter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/stream_omega_net.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/mem_to_banks.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/sram.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/addr_decode_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/cb_filter_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/cdc_2phase_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/cdc_2phase_clearable_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/cdc_fifo_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/cdc_fifo_clearable_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/fifo_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/graycode_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/id_queue_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/popcount_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/rr_arb_tree_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/stream_test.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/stream_register_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/stream_to_mem_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/sub_per_hash_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/isochronous_crossing_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/stream_omega_net_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/stream_xbar_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/clk_int_div_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/clk_int_div_static_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/clk_mux_glitch_free_tb.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/test/lossy_valid_to_stream_tb.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/clock_divider_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/clk_div.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/find_first_one.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/generic_LFSR_8bit.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/generic_fifo.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/prioarbiter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/pulp_sync.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/pulp_sync_wedge.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/rrarbiter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/clock_divider.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/fifo_v2.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/deprecated/fifo_v1.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/edge_propagator_ack.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/edge_propagator.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/src/edge_propagator_rx.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_pkg.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_intf.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_err_slv.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_regs.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_cdc.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_demux.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/src/apb_test.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/test/tb_apb_regs.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/test/tb_apb_cdc.sv" \
    "$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/test/tb_apb_demux.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_pkg.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_intf.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_atop_filter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_burst_splitter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_bus_compare.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_cdc_dst.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_cdc_src.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_cut.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_delayer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_demux_simple.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_dw_downsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_dw_upsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_fifo.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_id_remap.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_id_prepend.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_isolate.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_join.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_demux.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_dw_converter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_from_mem.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_join.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_lfsr.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_mailbox.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_mux.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_regs.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_to_apb.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_to_axi.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_modify_address.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_mux.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_rw_join.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_rw_split.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_serializer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_slave_compare.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_throttle.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_to_detailed_mem.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_cdc.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_demux.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_err_slv.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_dw_converter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_from_mem.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_id_serialize.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lfsr.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_multicut.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_to_axi_lite.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_to_mem.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_iw_converter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_lite_xbar.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_xbar.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_to_mem_banked.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_to_mem_interleaved.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_to_mem_split.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_xp.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_chan_compare.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_dumper.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_sim_mem.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/src/axi_test.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_dw_pkg.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_xbar_pkg.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_addr_test.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_atop_filter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_bus_compare.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_cdc.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_delayer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_dw_downsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_dw_upsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_fifo.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_isolate.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_lite_dw_converter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_lite_mailbox.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_lite_regs.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_iw_converter.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_lite_to_apb.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_lite_to_axi.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_lite_xbar.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_modify_address.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_serializer.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_sim_mem.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_slave_compare.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_to_axi_lite.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_to_mem_banked.sv" \
    "$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/test/tb_axi_xbar.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/idma_pkg.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_desc64_reg_pkg.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_reg32_3d_reg_pkg.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_reg64_2d_reg_pkg.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_desc64_reg_top.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_reg32_3d_reg_top.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_reg32_3d_top.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_reg64_2d_reg_top.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_reg64_2d_top.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_legalizer_rw_axi_rw_axis.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_transport_layer_rw_axi_rw_axis.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_backend_rw_axi_rw_axis.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_legalizer_rw_axi.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_transport_layer_rw_axi.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/idma_backend_rw_axi.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test/idma_intf.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test/idma_test.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/tb_idma_backend_rw_axi_rw_axis.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/tb_idma_backend_rw_axi.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/include" \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_intf.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/vendor/lowrisc_opentitan/src/prim_subreg_arb.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/vendor/lowrisc_opentitan/src/prim_subreg_ext.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/apb_to_reg.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/axi_lite_to_reg.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/axi_to_reg_v2.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/periph_to_reg.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_cdc.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_cut.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_demux.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_err_slv.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_filter_empty_writes.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_mux.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_to_apb.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_to_mem.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_to_tlul.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_uniform.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/vendor/lowrisc_opentitan/src/prim_subreg_shadow.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/vendor/lowrisc_opentitan/src/prim_subreg.sv" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/deprecated/axi_to_reg.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/apb-3ec2613a0fd03a97/include" \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/src/reg_test.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "$ROOT/.bender/git/checkouts/axi_mem_if-6cba168f201e1065/src/axi2mem.sv" \
    "$ROOT/.bender/git/checkouts/axi_mem_if-6cba168f201e1065/src/deprecated/axi_mem_if.sv" \
    "$ROOT/.bender/git/checkouts/axi_mem_if-6cba168f201e1065/src/deprecated/axi_mem_if_var_latency.sv" \
    "$ROOT/.bender/git/checkouts/axi_mem_if-6cba168f201e1065/src/deprecated/axi_mem_if_wrap.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/src/axi_stream_intf.sv" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/src/axi_stream_cut.sv" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/src/axi_stream_dw_downsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/src/axi_stream_dw_upsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/src/axi_stream_multicut.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/test/axi_stream_test.sv" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/test/tb_axi_stream_dw_downsizer.sv" \
    "$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/test/tb_axi_stream_dw_upsizer.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_axil_read.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_axil_write.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_axi_read.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_axi_write.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_axis_read.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_axis_write.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_channel_coupler.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_dataflow_element.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_error_handler.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_init_read.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_init_write.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_obi_read.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_obi_write.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_tilelink_read.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/backend/idma_tilelink_write.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/future/idma_improved_fifo.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/future/idma_legalizer_page_splitter.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/future/idma_legalizer_pow2_splitter.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/future/idma_reg_to_axi.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/midend/idma_mp_dist_midend.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/midend/idma_mp_split_midend.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/midend/idma_nd_midend.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/midend/idma_rt_midend.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_ar_gen.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_ar_gen_prefetch.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_reader.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_reader_gater.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_reshaper.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/idma_transfer_id_gen.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_reg_wrapper.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/frontend/desc64/idma_desc64_top.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/../../test" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/frontend/tb_idma_desc64_top.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/frontend/tb_idma_desc64_bench.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/future/idma_tb_per2axi.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/future/idma_obi_asserter.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/future/TLToAXI4.v" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/future/tb_idma_improved_fifo.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/midend/tb_idma_nd_midend.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/midend/tb_idma_rt_midend.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/future/idma_obi2axi_bridge.sv" \
    "$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/test/future/idma_tilelink2axi_bridge.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "+incdir+$ROOT/include" \
    "$ROOT/gen/eth_idma_reg_pkg.sv" \
    "$ROOT/gen/eth_idma_reg_top.sv" \
    "$ROOT/rtl/axis_gmii_rx.sv" \
    "$ROOT/rtl/axis_gmii_tx.sv" \
    "$ROOT/rtl/fll_dummy.sv" \
    "$ROOT/rtl/clk_gen_hyper.sv" \
    "$ROOT/rtl/eth_mac_1g_rgmii_fifo.sv" \
    "$ROOT/rtl/eth_mac_1g_rgmii.sv" \
    "$ROOT/rtl/eth_mac_1g.sv" \
    "$ROOT/rtl/iddr.sv" \
    "$ROOT/rtl/oddr.sv" \
    "$ROOT/rtl/rgmii_core.sv" \
    "$ROOT/rtl/rgmii_lfsr.sv" \
    "$ROOT/rtl/rgmii_phy_if.sv" \
    "$ROOT/rtl/rgmii_soc.sv" \
    "$ROOT/rtl/ssio_ddr_in.sv" \
    "$ROOT/rtl/framing_top.sv" \
    "$ROOT/rtl/eth_top.sv" \
    "$ROOT/rtl/eth_clk_gen.sv" \
    "$ROOT/rtl/eth_idma_wrap.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    -svinputport=compat \
    -override_timescale 1ns/1ps \
    -suppress 2583 \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_TEST \
    +define+TARGET_VSIM \
    "+incdir+$ROOT/.bender/git/checkouts/axi-47f77c70f1ff85d4/include" \
    "+incdir+$ROOT/.bender/git/checkouts/axi_stream-a50b87e6e786df95/include" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-5cd9baa0986cde44/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/src/include" \
    "+incdir+$ROOT/.bender/git/checkouts/idma-9c2c563d827a2a73/target/rtl/include" \
    "+incdir+$ROOT/.bender/git/checkouts/register_interface-ebea66ea9eaf865c/include" \
    "+incdir+$ROOT/include" \
    "$ROOT/target/sim/src/eth_idma_tb.sv" \
}]} {return 1}

vopt -permissive -suppress 3009 -suppress 8386 -error 7 +UVM_NO_RELNOTES -O5 +acc=p+eth_idma_tb. +noacc=p+eth_idma_wrap. eth_idma_tb -o eth_idma_tb_opt
