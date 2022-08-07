using System;
using System.IO;
using System.Interop;

namespace Shaderc {
	static class Shaderc {
		[AllowDuplicates]
		public enum TargetEnv : c_uint {
			/// SPIR-V under Vulkan semantics
			Vulkan,

			/// SPIR-V under OpenGL semantics
			OpenGL,

			// NOTE: SPIR-V code generation is not supported for shaders under OpenGL compatibility profile.

			/// SPIR-V under OpenGL semantics, including compatibility profile functions
			OpenGLCompat,

			/// Deprecated, SPIR-V under WebGPU semantics
			WebGPU,
			
			Default = Vulkan
		}

		public enum EnvVersion : c_uint {
			/// For Vulkan, use Vulkan's mapping of version numbers to integers.
			Vulkan_1_0 = 1u << 22,
			Vulkan_1_1 = (1u << 22) | (1 << 12),
			Vulkan_1_2 = (1u << 22) | (2 << 12),
			Vulkan_1_3 = (1u << 22) | (3 << 12),

			/// For OpenGL, use the number from #version in shaders.
			/// TODO(dneto): Currently no difference between OpenGL 4.5 and 4.6.
			/// See glslang/Standalone/Standalone.cpp
			/// TODO(dneto): Glslang doesn't accept a OpenGL client version of 460.
			OpenGL_4_5 = 450,

			/// Deprecated, WebGPU env never defined versions
			WebGPU
		}

		/// The known versions of SPIR-V.
		public enum SpirvVersion : c_uint {
			// Use the values used for word 1 of a SPIR-V binary:
			// - bits 24 to 31: zero
			// - bits 16 to 23: major version number
			// - bits 8 to 15: minor version number
			// - bits 0 to 7: zero
			_1_0 = 0x010000u,
			_1_1 = 0x010100u,
			_1_2 = 0x010200u,
			_1_3 = 0x010300u,
			_1_4 = 0x010400u,
			_1_5 = 0x010500u,
			_1_6 = 0x010600u
		}

		/// Indicate the status of a compilation.
		public enum CompilationStatus : c_uint {
			Success,
			/// error stage deduction
			InvalidStage,
			CompilationError,
			/// unexpected failure
			InternalError,
			NullResultObject,
			InvalidAssembly,
			ValidationError,
			TransformationError,
			ConfigurationError
		}

		/// Source language kind.
		public enum SourceLanguage : c_uint {
		 	GLSL,
		  	HLSL
		}

		[AllowDuplicates]
		public enum ShaderKind : c_uint {
		  	// Forced shader kinds. These shader kinds force the compiler to compile the
		  	// source code as the specified kind of shader.
		  	Vertex,
		  	Fragment,
		  	Compute,
		  	Geometry,
		  	TessControl,
		  	TessEvaluation,

		  	GlslVertex = Vertex,
		  	GlslFragment = Fragment,
		  	GlslCompute = Compute,
		  	GlslGeometry = Geometry,
		  	GlslTessControl = TessControl,
		  	GlslTessEvaluation = TessEvaluation,

		  	// Deduce the shader kind from #pragma annotation in the source code. Compiler
		  	// will emit error if #pragma annotation is not found.
		  	GlslInferFromSource,

		  	// Default shader kinds. Compiler will fall back to compile the source code as
		  	// the specified kind of shader when #pragma annotation is not found in the
		  	// source code.
		  	GlslDefaultVertex,
		  	GlslDefaultFragment,
		  	GlslDefaultCompute,
		  	GlslDefaultGeometry,
		  	GlslDefaultTessControl,
		  	GlslDefaultTessEvaluation,

		  	SpirvAssembly,
		  	RayGen,
		  	AnyHit,
		  	ClosestHit,
		  	Miss,
		  	Intersection,
		  	Callable,

		  	GlslRayGen = RayGen,
		  	GlslAnyHit = AnyHit,
		  	GlslClosestHit = ClosestHit,
		  	GlslMiss = Miss,
		  	GlslIntersection = Intersection,
		  	GlslCallable = Callable,

		  	GlslDefaultRayGen,
		  	GlslDefaultAnyHit,
		  	GlslDefaultClosestHit,
		  	GlslDefaultMiss,
		  	GlslDefaultIntersection,
		  	GlslDefaultCallable,

		  	Task,
		  	Mesh,

		  	GlslTask = Task,
		  	GlslMesh = Mesh,

		  	GlslDefaultTask,
		  	GlslDefaultMesh
		}

		public enum Profile : c_uint {
			/// Used if and only if GLSL version did not specify profiles.
		  	None,
		  	Core,
			/// Disabled. This generates an error
		  	Compatibility,
		  	ES,
		}

		/// Optimization level.
		public enum OptimizationLevel : c_uint {
			/// no optimization
			Zero,
			/// optimize towards reducing code size
			Size,
			/// optimize towards performance
		  	Performance,
		}

		/// Resource limits.
		public enum Limit : c_uint {
		  	MaxLights,
		  	MaxClipPlanes,
		  	MaxTextureUnits,
		  	MaxTextureCoords,
		  	MaxVertexAttribs,
		  	MaxVertexUniformComponents,
		  	MaxVaryingFloats,
		  	MaxVertexTextureImageUnits,
		  	MaxCombinedTextureImageUnits,
		  	MaxTextureImageUnits,
		  	MaxFragmentUniformComponents,
		  	MaxDrawBuffers,
		  	MaxVertexUniformVectors,
		  	MaxVaryingVectors,
		  	MaxFragmentUniformVectors,
		  	MaxVertexOutputVectors,
		  	MaxFragmentInputVectors,
		  	MinIn_programTexelOffset,
		  	MaxProgramTexelOffset,
		  	MaxClipDistances,
		  	MaxComputeWorkGroupCountX,
		  	MaxComputeWorkGroupCountY,
		  	MaxComputeWorkGroupCountZ,
		  	MaxComputeWorkGroupSizeX,
		  	MaxComputeWorkGroupSizeY,
		  	MaxComputeWorkGroupSizeZ,
		  	MaxComputeUniformComponents,
		  	MaxComputeTextureImageUnits,
		  	MaxComputeImageUniforms,
		  	MaxComputeAtomicCounters,
		  	MaxComputeAtomicCounterBuffers,
		  	MaxVaryingComponents,
		  	MaxVertexOutputComponents,
		  	MaxGeometryInputComponents,
		  	MaxGeometryOutputComponents,
		  	MaxFragmentInputComponents,
		  	MaxImageUnits,
		  	MaxCombinedImageUnitsAndFragmentOutputs,
		  	MaxCombinedShaderOutputResources,
		  	MaxImageSamples,
		  	MaxVertexImageUniforms,
		  	MaxTessControlImageUniforms,
		  	MaxTessEvaluationImageUniforms,
		  	MaxGeometryImageUniforms,
		  	MaxFragmentImageUniforms,
		  	MaxCombinedImageUniforms,
		  	MaxGeometryTextureImageUnits,
		  	MaxGeometryOutputVertices,
		  	MaxGeometryTotalOutputComponents,
		  	MaxGeometryUniformComponents,
		  	MaxGeometryVaryingComponents,
		  	MaxTessControlInputComponents,
		  	MaxTessControlOutputComponents,
		  	MaxTessControlTextureImageUnits,
		  	MaxTessControlUniformComponents,
		  	MaxTessControlTotalOutputComponents,
		  	MaxTessEvaluationInputComponents,
		  	MaxTessEvaluationOutputComponents,
		  	MaxTessEvaluationTextureImageUnits,
		  	MaxTessEvaluationUniformComponents,
		  	MaxTessPatchComponents,
		  	MaxPatchVertices,
		  	MaxTessGenLevel,
		  	MaxViewports,
		  	MaxVertexAtomicCounters,
		  	MaxTessControlAtomicCounters,
		  	MaxTessEvaluationAtomicCounters,
		  	MaxGeometryAtomicCounters,
		  	MaxFragmentAtomicCounters,
		  	MaxCombinedAtomicCounters,
		  	MaxAtomicCounterBindings,
		  	MaxVertexAtomicCounterBuffers,
		  	MaxTessControlAtomicCounterBuffers,
		  	MaxTessEvaluationAtomicCounterBuffers,
		  	MaxGeometryAtomicCounterBuffers,
		  	MaxFragmentAtomicCounterBuffers,
		  	MaxCombinedAtomicCounterBuffers,
		  	MaxAtomicCounterBufferSize,
		  	MaxTransformFeedbackBuffers,
		  	MaxTransformFeedbackInterleavedComponents,
		  	MaxCullDistances,
		  	MaxCombinedClipAndCullDistances,
		  	MaxSamples
		}

		/// Uniform resource kinds.
		/// In Vulkan, uniform resources are bound to the pipeline via descriptors
		/// with numbered bindings and sets.
		public enum UniformKind : c_uint {
		  	/// Image and image buffer.
		  	Image,
		  	/// Pure sampler.
		  	Sampler,
		  	/// Sampled texture in GLSL, and Shader Resource View in HLSL.
		  	Texture,
		  	/// Uniform Buffer Object (UBO) in GLSL. Cbuffer in HLSL.
		  	Buffer,
		  	/// Shader Storage Buffer Object (SSBO) in GLSL.
		  	StorageBuffer,
		  	/// Unordered Access View, in HLSL. (Writable storage image or storage buffer.)
		  	UnorderedAccessView
		}

		/// An opaque handle to an object that manages all compiler state.
		public class Compiler {
			private void* handle;

			public this() {
				handle = shaderc_compiler_initialize();
			}

			public ~this() {
				shaderc_compiler_release(handle);
			}

			public CompilationResult CompileIntoSpv(StringView source, ShaderKind shaderKind, StringView inputFileName, StringView entryPointName, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_compile_into_spv(handle, source.ToScopeCStr!(), (.) source.Length, shaderKind, inputFileName.ToScopeCStr!(), entryPointName.ToScopeCStr!(), additionalOptions?.[Friend]handle));
			}

			public CompilationResult CompileIntoSpv(String source, ShaderKind shaderKind, StringView inputFileName, StringView entryPointName, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_compile_into_spv(handle, source.Ptr, (.) source.Length, shaderKind, inputFileName.ToScopeCStr!(), entryPointName.ToScopeCStr!(), additionalOptions?.[Friend]handle));
			}

			public CompilationResult CompileIntoSpvAssembly(StringView source, ShaderKind shaderKind, StringView inputFileName, StringView entryPointName, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_compile_into_spv_assembly(handle, source.ToScopeCStr!(), (.) source.Length, shaderKind, inputFileName.ToScopeCStr!(), entryPointName.ToScopeCStr!(), additionalOptions?.[Friend]handle));
			}

			public CompilationResult CompileIntoSpvAssembly(String source, ShaderKind shaderKind, StringView inputFileName, StringView entryPointName, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_compile_into_spv_assembly(handle, source.CStr(), (.) source.Length, shaderKind, inputFileName.ToScopeCStr!(), entryPointName.ToScopeCStr!(), additionalOptions?.[Friend]handle));
			}

			public CompilationResult CompileIntoPreprocessedText(StringView source, ShaderKind shaderKind, StringView inputFileName, StringView entryPointName, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_compile_into_preprocessed_text(handle, source.ToScopeCStr!(), (.) source.Length, shaderKind, inputFileName.ToScopeCStr!(), entryPointName.ToScopeCStr!(), additionalOptions?.[Friend]handle));
			}

			public CompilationResult CompileIntoPreprocessedText(String source, ShaderKind shaderKind, StringView inputFileName, StringView entryPointName, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_compile_into_preprocessed_text(handle, source.CStr(), (.) source.Length, shaderKind, inputFileName.ToScopeCStr!(), entryPointName.ToScopeCStr!(), additionalOptions?.[Friend]handle));
			}

			public CompilationResult AssembleIntoSpv(StringView sourceAssembly, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_assemble_into_spv(handle, sourceAssembly.ToScopeCStr!(), (.) sourceAssembly.Length, additionalOptions?.[Friend]handle));
			}

			public CompilationResult AssembleIntoSpv(String sourceAssembly, CompileOptions additionalOptions) {
				return new [Friend].(shaderc_assemble_into_spv(handle, sourceAssembly.CStr(), (.) sourceAssembly.Length, additionalOptions?.[Friend]handle));
			}

			// Native

			[CLink]
			private static extern void* shaderc_compiler_initialize();

			[CLink]
			private static extern void shaderc_compiler_release(void* handle);

			[CLink]
			private static extern void* shaderc_compile_into_spv(void* handle, c_char* sourceText, c_size sourceTextSize, ShaderKind shaderKind, c_char* inputFileName, c_char* entryPointName, void* additionalOptions);
			
			[CLink]
			private static extern void* shaderc_compile_into_spv_assembly(void* handle, c_char* sourceText, c_size sourceTextSize, ShaderKind shaderKind, c_char* inputFileName, c_char* entryPointName, void* additionalOptions);
			
			[CLink]
			private static extern void* shaderc_compile_into_preprocessed_text(void* handle, c_char* sourceText, c_size sourceTextSize, ShaderKind shaderKind, c_char* inputFileName, c_char* entryPointName, void* additionalOptions);

			[CLink]
			private static extern void* shaderc_assemble_into_spv(void* handle, c_char* sourceAssembly, c_size sourceAssemblySize, void* additionalOptions);
		}

		/// An opaque handle to an object that manages options to a single compilation result.
		public class CompileOptions {
			private void* handle;

			private IncludeResolveCallback resolver;
			private IncludeResultReleaseCallback releaser;
			private void* includeUserData;

			public this() {
				handle = shaderc_compile_options_initialize();

				shaderc_compile_options_set_include_callbacks(
					handle,
					=> ResolverRaw,
					=> ReleaserRaw,
					Internal.UnsafeCastToPtr(this)
				);
			}

			public this(CompileOptions options) {
				handle = shaderc_compile_options_clone(options.handle);
			}

			public ~this() {
				shaderc_compile_options_release(handle);

				delete resolver;
				delete releaser;
			}

			private static IncludeResult* ResolverRaw(void* userData, c_char* requestedSource, c_int type, c_char* requestingSource, c_size includeDepth) {
				CompileOptions options = (.) Internal.UnsafeCastToObject(userData);
				return options.resolver(options.includeUserData, .(requestedSource), (.) type, .(requestingSource), includeDepth);
			}

			private static void ReleaserRaw(void* userData, IncludeResult* includeResult) {
				CompileOptions options = (.) Internal.UnsafeCastToObject(userData);
				options.releaser(options.includeUserData, includeResult);
			}

			public void AddMacroDefinition(StringView name, StringView value) {
				shaderc_compile_options_add_macro_definition(handle, name.ToScopeCStr!(), (.) name.Length, value.ToScopeCStr!(), (.) value.Length);
			}

			public void SetSourceLanguage(SourceLanguage language) {
				shaderc_compile_options_set_source_language(handle, language);
			}

			public void SetGenerateDebugInfo() {
				shaderc_compile_options_set_generate_debug_info(handle);
			}

			public void SetOptimizationLevel(OptimizationLevel level) {
				shaderc_compile_options_set_optimization_level(handle, level);
			}

			public void SetForcedVersionProfile(int version, Profile profile) {
				shaderc_compile_options_set_forced_version_profile(handle, (.) version, profile);
			}

			public void SetIncludeCallbacks(IncludeResolveCallback resolver, IncludeResultReleaseCallback resultReleaser, void* userData = null) {
				delete this.resolver;
				delete this.releaser;

				this.resolver = resolver;
				this.releaser = resultReleaser;
				this.includeUserData = userData;
			}

			public void SetDirectoryIncludeCallbacks(StringView rootDirectory) {
				SetIncludeCallbacks(
					new (userData, requestedSource, type, requestingSource, includeDepth) => {
						String path = scope .();

						if (type == .Standard) Path.InternalCombine(path, rootDirectory, requestedSource);
						else {
							String dir = scope .();
							Path.GetDirectoryPath(requestingSource, dir);

							Path.InternalCombine(path, rootDirectory, dir, requestedSource);
						}

						if (File.Exists(path)) {
							String content = scope .();
							if (File.ReadAllText(path, content) == .Ok) return new .(path, content);
						}

						return new .("", "");
					},
					new (userData, includeResult) => {
						includeResult.Dispose();
					}
				);
			}

			public void SetSuppressWarnings() {
				shaderc_compile_options_set_suppress_warnings(handle);
			}

			public void SetTargetEnv(TargetEnv target, uint32 version) {
				shaderc_compile_options_set_target_env(handle, target, version);
			}

			public void SetTargetSpirv(SpirvVersion version) {
				shaderc_compile_options_set_target_spirv(handle, version);
			}

			public void SetWarningsAsErrors() {
				shaderc_compile_options_set_warnings_as_errors(handle);
			}

			public void SetLimit(Limit limit, int value) {
				shaderc_compile_options_set_limit(handle, limit, (.) value);
			}

			public void SetAutoBindUniforms(bool autoBind) {
				shaderc_compile_options_set_auto_bind_uniforms(handle, autoBind);
			}

			public void SetAutoCombinedImageSampler(bool upgrade) {
				shaderc_compile_options_set_auto_combined_image_sampler(handle, upgrade);
			}

			public void SetHlslIoMapping(bool ioMap) {
				shaderc_compile_options_set_hlsl_io_mapping(handle, ioMap);
			}

			public void SetHlslOffsets(bool offsets) {
				shaderc_compile_options_set_hlsl_offsets(handle, offsets);
			}

			public void SetBindingBase(UniformKind kind, uint32 bindingBase) {
				shaderc_compile_options_set_binding_base(handle, kind, bindingBase);
			}

			public void SetBindingBaseForStage(ShaderKind shaderKind, UniformKind kind, uint32 bindingBase) {
				shaderc_compile_options_set_binding_base_for_stage(handle, shaderKind, kind, bindingBase);
			}

			public void SetAutoMapLocations(bool autoMap) {
				shaderc_compile_options_set_auto_map_locations(handle, autoMap);
			}

			public void SetHlslRegisterSetAndBindingForStage(ShaderKind shaderKind, StringView register, StringView set, StringView binding) {
				shaderc_compile_options_set_hlsl_register_set_and_binding_for_stage(handle, shaderKind, register.ToScopeCStr!(), set.ToScopeCStr!(), binding.ToScopeCStr!());
			}

			public void SetHlslRegisterSetAndBinding(StringView register, StringView set, StringView binding) {
				shaderc_compile_options_set_hlsl_register_set_and_binding(handle, register.ToScopeCStr!(), set.ToScopeCStr!(), binding.ToScopeCStr!());
			}

			public void SetHlslFunctionality1(bool enable) {
				shaderc_compile_options_set_hlsl_functionality1(handle, enable);
			}

			public void SetHlsl16BitTypes(bool enable) {
				shaderc_compile_options_set_hlsl_16bit_types(handle, enable);
			}

			public void SetInvertY(bool enable) {
				shaderc_compile_options_set_invert_y(handle, enable);
			}

			public void SetNanClamp(bool enable) {
				shaderc_compile_options_set_nan_clamp(handle, enable);
			}

			// Native

			[CLink]
			private static extern void* shaderc_compile_options_initialize();

			[CLink]
			private static extern void* shaderc_compile_options_clone(void* handle);

			[CLink]
			private static extern void shaderc_compile_options_release(void* handle);

			[CLink]
			private static extern void shaderc_compile_options_add_macro_definition(void* handle, c_char* name, c_size nameLength, c_char* value, c_size valueLength);

			[CLink]
			private static extern void shaderc_compile_options_set_source_language(void* handle, SourceLanguage language);

			[CLink]
			private static extern void shaderc_compile_options_set_generate_debug_info(void* handle);

			[CLink]
			private static extern void shaderc_compile_options_set_optimization_level(void* handle, OptimizationLevel level);

			[CLink]
			private static extern void shaderc_compile_options_set_forced_version_profile(void* handle, c_int version, Profile profile);

			[CLink]
			private static extern void shaderc_compile_options_set_include_callbacks(void* handle, IncludeResolveCallbackRaw resolver, IncludeResultReleaseCallbackRaw resultReleaser, void* userData);

			[CLink]
			private static extern void shaderc_compile_options_set_suppress_warnings(void* handle);

			[CLink]
			private static extern void shaderc_compile_options_set_target_env(void* handle, TargetEnv target, uint32 version);

			[CLink]
			private static extern void shaderc_compile_options_set_target_spirv(void* handle, SpirvVersion version);

			[CLink]
			private static extern void shaderc_compile_options_set_warnings_as_errors(void* handle);

			[CLink]
			private static extern void shaderc_compile_options_set_limit(void* handle, Limit limit, c_int value);

			[CLink]
			private static extern void shaderc_compile_options_set_auto_bind_uniforms(void* handle, c_bool autoBind);

			[CLink]
			private static extern void shaderc_compile_options_set_auto_combined_image_sampler(void* handle, c_bool upgrade);

			[CLink]
			private static extern void shaderc_compile_options_set_hlsl_io_mapping(void* handle, c_bool hlslIoMap);

			[CLink]
			private static extern void shaderc_compile_options_set_hlsl_offsets(void* handle, bool hlslOffsets);

			[CLink]
			private static extern void shaderc_compile_options_set_binding_base(void* handle, UniformKind kind, uint32 bindingBase);

			[CLink]
			private static extern void shaderc_compile_options_set_binding_base_for_stage(void* handle, ShaderKind shaderKind, UniformKind kind, uint32 bindingBase);

			[CLink]
			private static extern void shaderc_compile_options_set_auto_map_locations(void* handle, c_bool autoMap);

			[CLink]
			private static extern void shaderc_compile_options_set_hlsl_register_set_and_binding_for_stage(void* handle, ShaderKind shaderKind, c_char* reg, c_char* set, c_char* binding);

			[CLink]
			private static extern void shaderc_compile_options_set_hlsl_register_set_and_binding(void* handle, c_char* reg, c_char* set, c_char* binding);

			[CLink]
			private static extern void shaderc_compile_options_set_hlsl_functionality1(void* handle, c_bool enable);

			[CLink]
			private static extern void shaderc_compile_options_set_hlsl_16bit_types(void* handle, c_bool enable);

			[CLink]
			private static extern void shaderc_compile_options_set_invert_y(void* handle, c_bool enable);

			[CLink]
			private static extern void shaderc_compile_options_set_nan_clamp(void* handle, c_bool enable);
		}

		[CRepr]
		/// An include result.
		public struct IncludeResult : IDisposable {
			public c_char* sourceName;
			public c_size sourceNameLength;

			public c_char* content;
			public c_size contentLength;

			public void* userData;

			public this(StringView sourceName, StringView content, void* userData = null) {
				this.sourceName = new .[sourceName.Length]*;
				this.sourceNameLength = (.) sourceName.Length;
				Internal.MemCpy(this.sourceName, sourceName.ToRawData().Ptr, sourceName.Length);

				this.content = new .[content.Length]*;
				this.contentLength = (.) content.Length;
				Internal.MemCpy(this.content, content.ToRawData().Ptr, content.Length);

				this.userData = userData;
			}

			public void Dispose() mut {
				delete sourceName;
				delete content;

				delete &this;
			}
		}

		/// The kinds of include requests.
		public enum IncludeType : c_uint {
			/// E.g. #include "source"
		  	Relative,
			/// E.g. #include <source>
		  	Standard
		}

		private function IncludeResult* IncludeResolveCallbackRaw(void* userData, c_char* requestedSource, c_int type, c_char* requestingSource, c_size includeDepth);
		public delegate IncludeResult* IncludeResolveCallback(void* userData, StringView requestedSource, IncludeType type, StringView requestingSource, uint includeDepth);

		private function void IncludeResultReleaseCallbackRaw(void* userData, IncludeResult* includeResult);
		public delegate void IncludeResultReleaseCallback(void* userData, IncludeResult* includeResult);

		/// An opaque handle to the results of a call to any shaderc_compile_into_*() function.
		public class CompilationResult {
			private void* handle;

			private this(void* handle) {
				this.handle = handle;
			}

			public ~this() {
				shaderc_result_release(handle);
			}

			public CompilationStatus Status => shaderc_result_get_compilation_status(handle);

			public uint Warnings => shaderc_result_get_num_warnings(handle);
			public uint Errors => shaderc_result_get_num_errors(handle);

			public StringView ErrorMessage => .(shaderc_result_get_error_message(handle));

			public uint Length => shaderc_result_get_length(handle);
			public uint8* Bytes => (.) shaderc_result_get_bytes(handle);

			public uint SpvLength => Length / 4;
			public uint32* Spv => (.) Bytes;

			public StringView Text => .((char8*) Bytes, (.) Length);

			// Native

			[CLink]
			private static extern void shaderc_result_release(void* handle);

			[CLink]
			private static extern c_size shaderc_result_get_length(void* handle);

			[CLink]
			private static extern c_size shaderc_result_get_num_warnings(void* handle);

			[CLink]
			private static extern c_size shaderc_result_get_num_errors(void* handle);

			[CLink]
			private static extern CompilationStatus shaderc_result_get_compilation_status(void* handle);

			[CLink]
			private static extern c_char* shaderc_result_get_bytes(void* handle);

			[CLink]
			private static extern c_char* shaderc_result_get_error_message(void* handle);
		}

		/// Provides the version & revision of the SPIR-V which will be produced
		public static void GetSpvVersion(uint32* version, uint32* revision) {
			shaderc_get_spv_version(version, revision);
		}

		/// Parses the version and profile from a given null-terminated string
		/// containing both version and profile, like: '450core'. Returns false if
		/// the string can not be parsed. Returns true when the parsing succeeds. The
		/// parsed version and profile are returned through arguments.
		public static bool ParseVersionProfile(StringView str, int32* version, Profile* profile) {
			return shaderc_parse_version_profile(str.ToScopeCStr!(), version, profile);
		}

		// Native

		[CLink]
		private static extern void shaderc_get_spv_version(c_uint* version, c_uint* revision);

		[CLink]
		private static extern c_bool shaderc_parse_version_profile(c_char* str, c_int* version, Profile* profile);
	}
}