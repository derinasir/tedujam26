using Godot;

namespace new_project.scripts.PaintableThings;

public partial class DrawOnSprite : Sprite2D
{

    private Image _image;
    private ImageTexture _texture;

    public override void _Ready()
    {
        // Get the texture and convert it to an editable Image
        _texture = Texture as ImageTexture;
        if (_texture != null) _image = _texture.GetImage();
    }

    private void DrawPixel(Vector2I pos, Color color)
    {
        // Safety check: keep inside bounds
        if (pos.X < 0 || pos.Y < 0 || pos.X >= _image.GetWidth() || pos.Y >= _image.GetHeight())
            return;

        _image.SetPixelv(pos, color);

        // Push updated image back to GPU
        _texture.Update(_image);
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
        {
            // Convert global mouse position to local sprite space
            Vector2 localPos = ToLocal(mouseEvent.Position);
            
            // Convert to pixel coordinates
            Vector2I pixelPos = new Vector2I((int)localPos.X, (int)localPos.Y);
            GD.Print(pixelPos);
            DrawPixel(pixelPos, Colors.Red);
        }
    }

}