#include "my_application.h"

#include <cstring>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* theme_channel;
  FlMethodChannel* window_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Handler for pin/theme MethodChannel to synchronize GTK window theme
static void theme_method_call_cb(FlMethodChannel* channel,
                                 FlMethodCall* method_call,
                                 gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "setTheme") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    gboolean is_dark = FALSE;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* is_dark_val = fl_value_lookup_string(args, "isDark");
      if (is_dark_val != nullptr &&
          fl_value_get_type(is_dark_val) == FL_VALUE_TYPE_BOOL) {
        is_dark = fl_value_get_bool(is_dark_val);
      }
    }
    GtkSettings* settings = gtk_settings_get_default();
    if (settings != nullptr) {
      g_object_set(G_OBJECT(settings), "gtk-application-prefer-dark-theme",
                   is_dark, NULL);
    }
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
    fl_method_call_respond(method_call, response, nullptr);
  } else {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
  }
}

// Handler for pin/window MethodChannel to support window actions (drag, close)
static void window_method_call_cb(FlMethodChannel* channel,
                                  FlMethodCall* method_call,
                                  gpointer user_data) {
  // Look the window up on each call instead of keeping a raw pointer that
  // would dangle once the window is destroyed.
  GtkWindow* window =
      gtk_application_get_active_window(GTK_APPLICATION(user_data));
  if (window == nullptr) {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
        fl_method_error_response_new("no_window", "No active window", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "close") == 0) {
    gtk_window_close(window);
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
    fl_method_call_respond(method_call, response, nullptr);
  } else if (strcmp(method, "drag") == 0) {
    GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
    if (seat != nullptr) {
      GdkDevice* pointer = gdk_seat_get_pointer(seat);
      if (pointer != nullptr) {
        gint root_x = 0, root_y = 0;
        gdk_device_get_position(pointer, nullptr, &root_x, &root_y);
        gtk_window_begin_move_drag(window, 1, root_x, root_y, gtk_get_current_event_time());
      }
    }
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
    fl_method_call_respond(method_call, response, nullptr);
  } else if (strcmp(method, "resize") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* edge_str = "south";
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* edge_val = fl_value_lookup_string(args, "edge");
      if (edge_val != nullptr && fl_value_get_type(edge_val) == FL_VALUE_TYPE_STRING) {
        edge_str = fl_value_get_string(edge_val);
      }
    }
    GdkWindowEdge edge = GDK_WINDOW_EDGE_SOUTH;
    if (strcmp(edge_str, "north") == 0) {
      edge = GDK_WINDOW_EDGE_NORTH;
    } else if (strcmp(edge_str, "south") == 0) {
      edge = GDK_WINDOW_EDGE_SOUTH;
    }
    GdkSeat* seat = gdk_display_get_default_seat(gdk_display_get_default());
    if (seat != nullptr) {
      GdkDevice* pointer = gdk_seat_get_pointer(seat);
      if (pointer != nullptr) {
        gint root_x = 0, root_y = 0;
        gdk_device_get_position(pointer, nullptr, &root_x, &root_y);
        gtk_window_begin_resize_drag(window, edge, 1, root_x, root_y, gtk_get_current_event_time());
      }
    }
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
    fl_method_call_respond(method_call, response, nullptr);
  } else {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Remove the native application top bar / window title bar to achieve a sleek,
  // custom companion design without redundant headers.
  gtk_window_set_title(window, "Pin");
  gtk_window_set_decorated(window, FALSE);

  // Enable window resizing
  gtk_window_set_resizable(window, TRUE);

  // Fixed companion width (430px) - minimum height 400px
  gtk_widget_set_size_request(GTK_WIDGET(window), 430, 400);

  // Query primary monitor workarea so Pin defaults to full screen height
  GdkDisplay* display = gdk_display_get_default();
  GdkMonitor* monitor = nullptr;
  if (display != nullptr) {
    monitor = gdk_display_get_primary_monitor(display);
    if (monitor == nullptr && gdk_display_get_n_monitors(display) > 0) {
      monitor = gdk_display_get_monitor(display, 0);
    }
  }

  gint full_height = 900;
  if (monitor != nullptr) {
    GdkRectangle workarea;
    gdk_monitor_get_workarea(monitor, &workarea);
    if (workarea.height > 0) {
      full_height = workarea.height;
    }
  }

  // Constrain resizing strictly to height only (width stays fixed at 430px)
  GdkGeometry geometry;
  memset(&geometry, 0, sizeof(geometry));
  geometry.min_width = 430;
  geometry.max_width = 430;
  geometry.base_width = 430;
  geometry.min_height = 400;
  geometry.max_height = full_height > 2400 ? full_height : 2400;

  gtk_window_set_geometry_hints(
      window,
      nullptr,
      &geometry,
      static_cast<GdkWindowHints>(GDK_HINT_MIN_SIZE | GDK_HINT_MAX_SIZE | GDK_HINT_BASE_SIZE));

  // If window manager attempts to maximize the window, revert to companion width
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(+[](GtkWidget* widget, GdkEventWindowState* event, gpointer) -> gboolean {
                     if (event->changed_mask & GDK_WINDOW_STATE_MAXIMIZED) {
                       if (event->new_window_state & GDK_WINDOW_STATE_MAXIMIZED) {
                         gtk_window_unmaximize(GTK_WINDOW(widget));
                       }
                     }
                     return FALSE;
                   }),
                   nullptr);

  // Default dimensions: fixed 430px width, full monitor workarea height
  gtk_window_set_default_size(window, 430, full_height);

  // Set window icon for window managers, docks, and Alt-Tab
  gtk_window_set_icon_name(window, "pin");
  const char* icon_path = "/home/cris92bb/Desktop/Projects/Pin/assets/icons/pin.png";
  if (g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
    gtk_window_set_icon_from_file(window, icon_path, nullptr);
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Register pin/theme MethodChannel to synchronize GTK window theme with app
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  // Channels are owned by the application and released in dispose.
  self->theme_channel = fl_method_channel_new(
      messenger, "pin/theme", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->theme_channel, theme_method_call_cb, nullptr, nullptr);

  // Register pin/window MethodChannel to support window actions (drag, close)
  self->window_channel = fl_method_channel_new(
      messenger, "pin/window", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->window_channel, window_method_call_cb, application, nullptr);

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

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->theme_channel);
  g_clear_object(&self->window_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
