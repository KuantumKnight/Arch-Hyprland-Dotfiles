#include <gtk/gtk.h>
#include <gmodule.h>

/* Loaded through Nemo's --gtk-module argument, never the session environment. */
G_MODULE_EXPORT void gtk_module_init(gint *argc, gchar ***argv) {
    (void)argc;
    (void)argv;
    GtkSettings *settings = gtk_settings_get_default();
    if (settings)
        g_object_set(settings, "gtk-icon-theme-name", "Fluent-dark", NULL);
}
