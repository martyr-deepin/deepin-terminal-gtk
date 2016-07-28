#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <glib.h>

gchar** list_mono_fonts(int* num) {
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
	    if (strcmp((char*) FcPatternFormat(fs->fonts[j], (FcChar8*)"%{spacing}"), "100") == 0) {
		    /* Realloc was realloc(fonts, 0), and you have to take space for <char *> */
		    fonts = realloc(fonts, (count + 1) * sizeof(gchar*));
			if (fonts == NULL) {
			    fprintf(stderr, "Alloc memory at append %d font info failed\n", count + 1);
			    return NULL;
			}

			/* Got font name */
			gchar* font = (gchar*) FcPatternFormat(fs->fonts[j], (FcChar8*)"%{family}");
			
			/* Need space for store font */
			fonts[count] = malloc(strlen(font) + 1);
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

/* void main(int argc, char *argv[]) { */
/*     int font_num = 0; */
/*     char** fonts = list_mono_fonts(&font_num); */
	
/* 	int i; */
/* 	for (i = 0; i < font_num; i++) { */
/* 	    printf("%s\n", fonts[i]); */
/* 	} */
	
/* 	printf("\n"); */
/* 	printf("%s", font_match("mono")); */
/* } */
  
