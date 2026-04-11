using Godot;

namespace new_project.scripts.PaintableThings;

public partial class WorldPainter : Sprite2D
{
    private Image _image;
    private ImageTexture _texture;

    [Export] public int Width = 1024;
    [Export] public int Height = 1024;

    public override void _Ready()
    {
        // Create empty image (your "world canvas")
        _image = Image.Create(Width, Height, false, Image.Format.Rgba8);
        _image.Fill(Colors.Transparent);

        _texture = ImageTexture.CreateFromImage(_image);
        Texture = _texture;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouse && mouse.Pressed)
        {
            // Convert global → local canvas space
            Vector2 local = ToLocal(mouse.Position);

            Vector2I pixel = new Vector2I((int)local.X, (int)local.Y);

            DrawBrush(pixel, 8, Colors.Red);
        }
    }

    private void DrawBrush(Vector2I center, int radius, Color color)
    {
        for (int x = -radius; x <= radius; x++)
        {
            for (int y = -radius; y <= radius; y++)
            {
                if (x * x + y * y > radius * radius)
                    continue;

                Vector2I pos = center + new Vector2I(x, y);

                if (pos.X < 0 || pos.Y < 0 || pos.X >= _image.GetWidth() || pos.Y >= _image.GetHeight())
                    continue;

                _image.SetPixelv(pos, color);
            }
        }

        _texture.Update(_image);
    }
}