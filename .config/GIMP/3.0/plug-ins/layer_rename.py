from gimpfu import *

def rename_layers(image, drawable, prefix):
    """Rename all layers in the image with a given prefix."""
    for i, layer in enumerate(image.layers):
        new_name = f"{prefix}_{i+1}"
        pdb.gimp_item_set_name(layer, new_name)
    pdb.gimp_displays_flush()  # Refresh the GIMP UI

register(
    "python_fu_rename_layers",
    "Rename all layers with a prefix",
    "Renames all layers in the current image using a given prefix",
    "Himadri",
    "Himadri",
    "2025",
    "<Image>/Python-Fu/Layer Rename",
    "*",  # Works on any image type
    [
        (PF_STRING, "prefix", "Prefix for layer names", "Layer")
    ],
    [],
    rename_layers
)

main()

