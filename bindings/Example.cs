using System;
using IcuBreakIterator.Native;

public class Example
{
    public static void Main()
    {
        // Optional: Only needed if automatic loading doesn't work
        // ManualLoader.LoadLibrary();
        
        // Get ICU version
        Console.WriteLine($"ICU Version: {IcuBreakIterator.GetVersion()}");

        // Create break iterator
        using var breakIterator = new IcuBreakIterator("en_US");
        
        string text = "Hello world. This is a test. How are you?";
        breakIterator.SetText(text);

        Console.WriteLine($"Text: {text}");
        Console.WriteLine("\nBreak positions:");

        int position = breakIterator.First();
        while ((position = breakIterator.Next()) != IcuBreakIterator.UBRK_DONE)
        {
            Console.WriteLine($"  Position {position}: '{text.Substring(0, position)}'");
        }
    }
}
