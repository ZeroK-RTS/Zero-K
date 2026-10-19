/* SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
void* SDL_CreateWindow(const char* title,int x,int y,int w,int h,uint32_t flags)
{
 void* (*create)(const char*,int,int,int,int,uint32_t)=dlsym(RTLD_NEXT,"SDL_CreateWindow");
 return create(title,x,y,w,h,(flags & ~4u)|8u);
}
void SDL_ShowWindow(void* window) {}
void SDL_RaiseWindow(void* window) {}
