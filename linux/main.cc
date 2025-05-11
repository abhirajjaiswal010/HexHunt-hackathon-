#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include "my_application.h"

int main(int argc, char** argv) {
  // Initialize GTK
  gtk_init(&argc, &argv);

  // Create the Flutter application
  g_autoptr(MyApplication) app = my_application_new();
  
  // Set up window properties
  GtkWindow* window = GTK_WINDOW(gtk_application_get_active_window(GTK_APPLICATION(app)));
  gtk_window_set_title(window, "HexHunt");
  gtk_window_set_default_size(window, 1280, 720);
  gtk_window_set_resizable(window, TRUE);
  
  // Set up window decorations
  gtk_window_set_decorated(window, TRUE);
  gtk_window_set_skip_taskbar_hint(window, FALSE);
  gtk_window_set_skip_pager_hint(window, FALSE);
  
  // Set up window icon
  GdkPixbuf* icon = gdk_pixbuf_new_from_file("data/flutter_assets/assets/app_icon.png", nullptr);
  if (icon != nullptr) {
    gtk_window_set_icon(window, icon);
    g_object_unref(icon);
  }

  // Run the application
  int status = g_application_run(G_APPLICATION(app), argc, argv);
  
  return status;
} 