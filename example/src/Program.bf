using System;
using Shaderc;

namespace Example {
	class Program {
		public static void Main() {
			Shaderc.Compiler compiler = scope .();

			Shaderc.CompilationResult result = compiler.CompileIntoSpv("", .Vertex, "", "", null);
			PrintResult(result);
			delete result;

			Shaderc.CompileOptions options = scope .();
			options.AddMacroDefinition("SOMETHING", "TRUE");

			options.SetIncludeCallbacks(new (userData, requestedSource, type, requestingSource, includeDepth) => {
				return new .(requestedSource, "float foo() { return 2.0; }");
			}, new (userData, includeResult) => {
				includeResult.Dispose();
			});

			//options.SetDirectoryIncludeCallbacks(".");

			result = compiler.CompileIntoSpv("""
				#version 450

				layout(location = 0) in vec2 position;

				#include "foo.glsl"

				void main() {
					gl_Position = vec4(position, 0.0, 0.0);

					#ifdef SOMETHING
						gl_Position *= foo();
					#endif
				}
				""", .Vertex, "foo/cope.vert", "main", options);
			PrintResult(result);
			delete result;

			Console.Read();
		}

		private static void PrintResult(Shaderc.CompilationResult result) {
			Console.WriteLine("Status: {}", result.Status);
			Console.WriteLine("Warnings: {}", result.Warnings);
			Console.WriteLine("Errors: {}", result.Errors);
			Console.WriteLine("Length: {}", result.Length);
			Console.WriteLine("{}", result.ErrorMessage);
		}
	}
}