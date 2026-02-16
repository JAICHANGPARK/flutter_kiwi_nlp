# flutter_kiwi_ffi_example

Kiwi analyzer demo app for `flutter_kiwi_ffi`.

## Model setup

No app-level model asset setup is required.

`KiwiAnalyzer.create()` works without model path arguments.
On native platforms, if no model is found locally, the plugin downloads the default base model once and caches it.
