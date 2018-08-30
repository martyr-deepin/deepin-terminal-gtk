/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2018 Deepin, Inc.
 *               2011 ~ 2018 Wang Yong
 *
 * Author:     Wang Yong <wangyong@deepin.com>
 * Maintainer: Wang Yong <wangyong@deepin.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <regex.h>
#include <glib.h>

static int string_rematch(const char* string,const char* pattern) {
    int ret = 0;
    regex_t regex;
    regcomp(&regex, pattern, REG_ICASE);
    if (regexec(&regex, string, 0, NULL, 0) == REG_NOERROR)
        ret = 1;
    regfree(&regex);
    return ret;
}

gchar** list_mono_or_dot_fonts(gint* num, int* result_length) {
    FcInit();

    FcPattern *pat = FcPatternCreate();
    if (!pat) {
        fprintf(stderr, "Create FcPattern Failed\n");
        return NULL;
    }

    FcObjectSet *os = FcObjectSetBuild(
        FC_FAMILY,
        FC_FAMILYLANG,
        FC_FULLNAME,
        FC_FULLNAMELANG,
        FC_STYLE,
        FC_FILE,
        FC_LANG,
        FC_SPACING,
        FC_CHARSET,
        NULL);
    if (!os) {
        fprintf(stderr, "Build FcObjectSet Failed\n");
        FcPatternDestroy(pat);
        return NULL;
    }

    FcFontSet *fs = FcFontList(0, pat, os);
    FcObjectSetDestroy(os);
    FcPatternDestroy(pat);
    if (!fs) {
        fprintf(stderr, "List Font Failed\n");
        return NULL;
    }

    /* Read family name of mono font. */
    gchar** fonts = NULL;
    int j;
    int count = 0;
    for (j = 0; j < fs->nfont; j++) {
        /* printf("family: %s\n familylang: %s\n fullname: %s\n fullnamelang: %s\n style: %s\n file: %s\n lang: %s\n spacing: %s\n charset: %s\n", */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{family}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{familylang}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{fullname}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{fullnamelang}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{style}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{file}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{lang}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{spacing}"), */
        /*       FcPatternFormat(fs->fonts[j], (FcChar8*)"%{charset}") */
        /*       ); */

    char *font_family = (char*) FcPatternFormat(fs->fonts[j], (FcChar8*)"%{family}");
    char *comma = NULL;

    // split with ',' and using last one
    while ((comma = strchr(font_family, ',')) != NULL)
        font_family = comma + 1;

        /* spacing 100 is mono font, spacing 110 is dot font */
        if (strcmp((char*) FcPatternFormat(fs->fonts[j], (FcChar8*)"%{spacing}"), "100") == 0
            || strcmp((char*) FcPatternFormat(fs->fonts[j], (FcChar8*)"%{spacing}"), "110") == 0
            || string_rematch(font_family, "mono")
            || strcmp(font_family, "YaHei Consolas Hybrid") == 0
            || strcmp(font_family, "Monaco") == 0
            ) {
            /* Realloc was realloc(fonts, 0), and you have to take space for <char *> */
            fonts = realloc(fonts, (count + 1) * sizeof(gchar*));
            if (fonts == NULL) {
                fprintf(stderr, "Alloc memory at append %d font info failed\n", count + 1);
                return NULL;
            }

            /* Filter charset font */
            char *charset = (char*)FcPatternFormat(fs->fonts[j], (FcChar8*)"%{charset}");
            if (charset == NULL || strlen(charset) == 0) {
                free(charset);
                continue;
            }
            free(charset);

            /* Got font name */
            gchar* font = g_strdup(font_family);

            /* Need space for store font */
            fonts[count] = malloc((strlen(font) + 1) * sizeof(gchar));
            if (fonts[count] == NULL) {
                fprintf(stderr, "Malloc %d failed\n", count + 1);
                return NULL;
            }

            strcpy(fonts[count], font);

            free(font);

            count++;
        }
    }

    /* Remove duplicate font family. */
    int i, k;
    for (i = 0; i < count; i++) {
        for (j = i + 1; j < count;) {
            if (strcmp(fonts[j], fonts[i]) == 0) {
                for (k = j; k < count; k++) {
                    fonts[k] = fonts[k + 1];
                }
                count--;
            } else
              j++;
        }
    }
    *num = count;
    *result_length = count;

    FcFontSetDestroy(fs);

    return fonts;
}

gchar* font_match(gchar* family) {
     FcPattern* pat = FcNameParse((FcChar8*)family);
     if (!pat) {
         return NULL;
     }

     FcConfigSubstitute(NULL, pat, FcMatchPattern);
     FcDefaultSubstitute(pat);

     FcResult result;
     FcPattern* match = FcFontMatch(NULL, pat, &result);
     FcPatternDestroy(pat);
     if (!match) {
         return NULL;
     }

     FcFontSet* fs = FcFontSetCreate();
     if (!fs) {
         FcPatternDestroy(match);
         return NULL;
     }

     FcFontSetAdd(fs, match);
     FcPattern* font = FcPatternFilter(fs->fonts[0], NULL);
     FcChar8* ret = FcPatternFormat(font, (const FcChar8*)"%{family}");

     FcPatternDestroy(font);
     FcFontSetDestroy(fs);
     FcPatternDestroy(match);

     if (!ret) {
         return NULL;
     }

     return (gchar*)ret;
}

/* void main(int argc, char *argv[]) {
    gint num = 0;
    int font_num = 0;
    gchar** fonts = list_mono_or_dot_fonts(&num, &font_num);

    int i;
    for (i = 0; i < font_num; i++) {
        printf("%s\n", fonts[i]);
    }

    printf("\n");
    printf("%s", font_match("Mono"));
} */
