#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <handy.h>
#include <gdk/gdk.h>

#include "flutter/generated_plugin_registrant.h"

#ifdef NDEBUG
#define APPLICATION_FLAGS \
  G_APPLICATION_HANDLES_COMMAND_LINE | G_APPLICATION_HANDLES_OPEN
#else
#define APPLICATION_FLAGS G_APPLICATION_NON_UNIQUE
#endif

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Callback function to set the window size based on the monitor it's located on
void on_window_realize(GtkWidget* widget, gpointer user_data) {
  GdkRectangle monitor_geometry;
  GdkWindow* gdk_window = gtk_widget_get_window(widget);
  if (gdk_window == nullptr) {
    return;
  }

  GdkDisplay* display = gdk_window_get_display(gdk_window);
  GdkSeat* seat = gdk_display_get_default_seat(display);
  GdkDevice* pointer = gdk_seat_get_pointer(seat);

  // Get the current cursor position
  int x, y;
  gdk_device_get_position(pointer, nullptr, &x, &y);

  // Get the monitor at the cursor position
  GdkMonitor* monitor = gdk_display_get_monitor_at_point(display, x, y);

  if (monitor == nullptr) {
    return;
  }

  gdk_monitor_get_geometry(monitor, &monitor_geometry);
  gint screen_width = monitor_geometry.width;
  gint screen_height = monitor_geometry.height;

  // Predefined sizes
  const gint min_width = 800;
  const gint min_height = 600;
  const gint max_width = 1080;
  const gint max_height = 700;

  // Determine default window size based on screen size
  gint default_width = screen_width;
  gint default_height = screen_height;

  g_print("Default width: %d, Default height: %d\n", default_width, default_height);


  if (screen_width <= 1440 ) {
    default_width = min_width;
    default_height = min_height;
  } else {
    default_width = max_width;
    default_height = max_height;
  }

  g_print("Default width: %d, Default height: %d\n", default_width, default_height);


  GdkGeometry geometry;
  geometry.min_width = min_width;
  geometry.min_height = min_height;

  // gtk_window_set_geometry_hints(GTK_WINDOW(widget), nullptr, &geometry, GDK_HINT_MIN_SIZE);
  gtk_window_set_default_size(GTK_WINDOW(widget), default_width, default_height);
}


// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

#ifdef NDEBUG
  GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
  if (windows) {
    gtk_window_present(GTK_WINDOW(windows->data));
    return;
  }
#endif

  GtkWindow* window = GTK_WINDOW(hdy_application_window_new());
  gtk_window_set_application(window, GTK_APPLICATION(application));

  // Connect to the "realize" signal to get the monitor size after the window is realized
  g_signal_connect(window, "realize", G_CALLBACK(on_window_realize), nullptr);


  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

#ifdef NDEBUG
// Implements GApplication::command_line.
static gint my_application_command_line(GApplication* application,
                                        GApplicationCommandLine* command_line) {
  gchar** arguments =
      g_application_command_line_get_arguments(command_line, nullptr);
  gint exit_status = 0;
  my_application_local_command_line(application, &arguments, &exit_status);
  return exit_status;
}
#endif

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
#ifdef NDEBUG
  G_APPLICATION_CLASS(klass)->command_line = my_application_command_line;
#else
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
#endif
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     APPLICATION_FLAGS, nullptr));
}
