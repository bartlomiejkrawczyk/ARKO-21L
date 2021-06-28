#include <stdio.h>
#include <stdlib.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>

extern void scale(void *img, int width, int height, void *scaledImg, int newWidth, int newHeight);

int main(int argc, const char *argv[])
{
    ALLEGRO_DISPLAY *Screen;
    ALLEGRO_EVENT_QUEUE *EventQueue;
    ALLEGRO_EVENT Event;
    ALLEGRO_BITMAP *Image = NULL;
    bool Exit = false;

    if(!al_init())
    {
        printf("Allegro has failed to initialize.");
        return -1;
    }

    if(!al_init_image_addon())
    {
        printf("Image addon has failed to initialize.");
        return -1;
    }

    Screen = al_create_display(800, 600);
    if(Screen == NULL)
    {
        printf("Failed to create the display.");
        return -1;
    }

    EventQueue = al_create_event_queue();
    if(EventQueue == NULL)
    {
        printf("Failed to create the event queue.");
        return -1;
    }

    if(!al_install_mouse())
    {
        printf("Failed to install mouse.");
        return -1;
    }

    al_register_event_source(EventQueue, al_get_display_event_source(Screen));
    al_register_event_source(EventQueue, al_get_mouse_event_source());

    if (argc != 2) {
        printf("Please provide a filename e.g. images/5x5.bmp");
        return 0;
    }

    FILE *fp;
    fp = fopen(argv[1], "rb");

    if (fp == NULL) {
        printf("File not found.\n");
        return 0;
    }

    al_clear_to_color(al_map_rgb(255,255,255));

    Image = al_load_bitmap(argv[1]);

    al_draw_bitmap(Image, 0, 0, 0);
    al_flip_display();

    unsigned short headerField, bpp;
    fread(&headerField, 2, 1, fp);
    if (headerField != 0x4D42) {
        printf("File is not a supported image (header start is not \"BM\")\n");
        return 0;
    }

    fseek(fp, 28, SEEK_SET);
    fread(&bpp, 2, 1, fp);
    if (bpp != 24) {
        printf("Only 24 bpp is supported, %d were given.\n", bpp);
        return 0;
    }

    unsigned int width, height;
    fseek(fp, 18, SEEK_SET);
    fread(&width, 4, 1, fp);
    fread(&height, 4, 1, fp);

    unsigned int bmpSize, offset;

    fseek(fp, 2, SEEK_SET);
    fread(&bmpSize, 4, 1, fp);

    fseek(fp, 10, SEEK_SET);
    fread(&offset, 4, 1, fp);

    unsigned char *entireImg = malloc(bmpSize);
    void *img = entireImg + offset;

    fseek(fp, 0, SEEK_SET);
    fread(entireImg, 1, bmpSize, fp);
    fclose(fp);
    int newWidth = width;
    int newHeight = height;

    while(Exit == false)
    {

        al_wait_for_event(EventQueue, &Event);


        if(Event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN) ///check if a mouse button was clicked
        {
            newWidth = Event.mouse.x;
            newHeight = Event.mouse.y;

            int newBmpSize = (3 * newWidth + newWidth % 4) * newHeight;
            void *scaledImg = malloc(newBmpSize);
            newBmpSize += offset;

            unsigned char bmpfileheader[14] = {'B','M', 0,0,0,0, 0,0, 0,0, 54,0,0,0};
            unsigned char bmpinfoheader[40] = {40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0, 24,0};

            bmpfileheader[ 2] = (unsigned char)(newBmpSize    );
            bmpfileheader[ 3] = (unsigned char)(newBmpSize>> 8);
            bmpfileheader[ 4] = (unsigned char)(newBmpSize>>16);
            bmpfileheader[ 5] = (unsigned char)(newBmpSize>>24);

            bmpinfoheader[ 4] = (unsigned char)(newWidth    );
            bmpinfoheader[ 5] = (unsigned char)(newWidth>> 8);
            bmpinfoheader[ 6] = (unsigned char)(newWidth>>16);
            bmpinfoheader[ 7] = (unsigned char)(newWidth>>24);
            bmpinfoheader[ 8] = (unsigned char)(newHeight    );
            bmpinfoheader[ 9] = (unsigned char)(newHeight>> 8);
            bmpinfoheader[10] = (unsigned char)(newHeight>>16);
            bmpinfoheader[11] = (unsigned char)(newHeight>>24);


            scale(img, (int) width, (int) height, scaledImg, newWidth, newHeight);

            fp = fopen("images/result.bmp", "wb");
            if (fp == NULL) {
                printf("An error occurred while opening the file to write.\n");
                return 0;
            }
            fwrite(bmpfileheader, 1, 14, fp);
            fwrite(bmpinfoheader, 1, 40, fp);
            fwrite(scaledImg, 1, newBmpSize - offset, fp);
            fclose(fp);
            free(scaledImg);

            al_clear_to_color(al_map_rgb(255,255,255));


            Image = al_load_bitmap("images/result.bmp"); //load the bitmap from a file

            al_draw_bitmap(Image, 0, 0, 0);

            al_flip_display();
        }

        if(Event.type == ALLEGRO_EVENT_DISPLAY_CLOSE)
        {
            Exit = true;
        }

    }

    al_destroy_event_queue(EventQueue);
    al_destroy_display(Screen);
    free(entireImg);

    return 0;
}
