extern int download_begin(void);
extern void soft_reboot_begin(void);
extern void hard_reset_to_bootloader(void);
extern void hard_reset_to_user_code(void);
extern void download_cancel(const char *mesg);
extern void download_rx_port(const char *buf, int num);
extern void download_timer(void);
extern int download_in_progress(void);
