#ifndef MENU_H
#define MENU_H

void menu_init(void);
void menu_poll(void);
int menu_get_action(void);
int menu_get_audio_enabled(void);
void menu_set_paused(int paused);
void menu_set_folder(const char *path);
const char *menu_choose_folder(void);
const char *menu_get_selected_folder(void);
int menu_copy_selected_folder(unsigned char *buffer, int capacity);

#endif