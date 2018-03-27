// Public API for compiler

export "linker/component_factory.dart" show ComponentRef, ComponentFactory;
export "linker/component_loader.dart" show ComponentLoader;
// ignore: deprecated_member_use
export "linker/dynamic_component_loader.dart" show SlowComponentLoader;
export "linker/element_ref.dart" show ElementRef;
export "linker/exceptions.dart"
    show ExpressionChangedAfterItHasBeenCheckedException;
// ignore: deprecated_member_use
export "linker/query_list.dart" show QueryList;
export "linker/template_ref.dart" show TemplateRef;
export "linker/view_container_ref.dart" show ViewContainerRef;
export "linker/view_ref.dart" show EmbeddedViewRef, ViewRef;
