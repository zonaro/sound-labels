#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <string.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_arguments;
  gboolean quick_mode;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static void on_activate(GApplication* app) {
  MyApplication* self = MY_APPLICATION(app);
  GtkWindow* window = GTK_WINDOW(
      gtk_application_window_new(GTK_APPLICATION(app)));
  gtk_window_set_title(window, self->quick_mode ? "Sound Labels · Audio output"
                                                 : "Sound Labels");
  gtk_window_set_default_size(window, self->quick_mode ? 420 : 1024,
                              self->quick_mode ? 520 : 740);
  if (self->quick_mode) gtk_window_set_resizable(window, FALSE);
  g_autofree gchar* executable_path = g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path) {
    g_autofree gchar* executable_directory = g_path_get_dirname(executable_path);
    g_autofree gchar* icon_path = g_build_filename(executable_directory,
        "data", "flutter_assets", "assets", "icons", "sound-labels.svg", nullptr);
    gtk_window_set_icon_from_file(window, icon_path, nullptr);
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_arguments);
  FlView* view = fl_view_new(project);
  GdkRGBA background;
  gdk_rgba_parse(&background, "#ffffff");
  fl_view_set_background_color(view, &background);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));
  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static gboolean on_local_command_line(GApplication* app, gchar*** arguments,
                                      int* exit_status) {
  MyApplication* self = MY_APPLICATION(app);
  self->dart_arguments = g_strdupv(*arguments + 1);
  self->quick_mode = FALSE;
  for (gchar** arg = self->dart_arguments; arg && *arg; ++arg) {
    if (strcmp(*arg, "--quick") == 0) self->quick_mode = TRUE;
  }
  g_autoptr(GError) error = nullptr;
  if (!g_application_register(app, nullptr, &error)) {
    g_warning("Unable to register application: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }
  g_application_activate(app);
  *exit_status = 0;
  return TRUE;
}

static void on_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = on_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = on_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = on_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);
  return MY_APPLICATION(g_object_new(my_application_get_type(),
      "application-id", APPLICATION_ID,
      "flags", G_APPLICATION_NON_UNIQUE, nullptr));
}
