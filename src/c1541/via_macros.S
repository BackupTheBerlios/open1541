
#if CONFIG_VIA_TRACES
.macro via_report_access_r
        push    {lr}
        mov     r0, #'r'
        bl      via_report_access
        pop     {lr}
.endm

.macro via_report_access_w
        push    {lr}
        mov     r0, #'w'
        bl      via_report_access
        pop     {lr}
.endm
#else
.macro via_report_access_r
.endm
.macro via_report_access_w
.endm
#endif

.macro ifr_offet ier_offset
        @ update IRQ bit (bit 7) of IFR
        bic     m_data, m_data, #0x80           @ delete IRQ bit
        ldrb    m_tmp, [m_pdata, #\ier_offset]  @ load IER
        ands    m_tmp, m_tmp, m_data            @ combine IER and IFR
        orrne   m_data, m_data, #0x80           @ set IRQ in IFR if not 0
        strb    m_tmp, [m_pdata, #\ifr_offet]   @ store IFR
.endm

