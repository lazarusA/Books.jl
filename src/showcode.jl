"""
    remove_hide_comment(expr::AbstractString)

Remove lines which end with `# hide`.
"""
function remove_hide_comment(expr::AbstractString)
    expr = string(expr)::String
    lines = split(expr, '\n')
    lines = rstrip.(lines)
    lines = filter(!endswith("# hide"), lines)
    expr = join(lines, '\n')
end

"""
    @sc(f)

Show code for function `f`; to also show output, use [`@sco`](@ref).
"""
macro sc(f)
    println("Obtaining source code for $f")
    esc(quote
        s = Books.CodeTracking.@code_string $(f)
        s = Books.remove_hide_comment(s)
        Books.code_block(s)
    end)
end

"""
    CodeAndFunction(code::AbstractString, f)

This struct is used by [`@sco`](@ref).
"""
struct CodeAndFunction
    code::AbstractString
    f::Any
end

"""
    @sco(f)

Show code and output for `f()`; to show only code, use [`@sc`](@ref).
"""
macro sco(f)
    esc(quote
        code = @sc $(f)
        CodeAndFunction(code, $(f))
    end)
end

function convert_output(expr, path, cf::CodeAndFunction)
    code = cf.code
    f = cf.f
    out = f
    out = convert_output(expr, path, out)
    """
    $code
    $out
    """
end

"""
    eval_convert(expr::AbstractString, M,
    process::Union{Nothing,Function}=nothing,
    post::Union{Nothing,Function}=identity)

Evaluate `expr` in module `M` and convert the output.
"""
function eval_convert(expr::AbstractString, M,
    process::Union{Nothing,Function}=nothing,
    post::Union{Nothing,Function}=identity)
    ex = Meta.parse("begin $expr end")
    out = Core.eval(M, ex)
    out = isnothing(process) ? convert_output(expr, nothing, out) : process(out)
    out = post(out)
end

"""
    sco(expr::AbstractString;
    M=Main, process::Union{Nothing,Function}=nothing,
    post::Function=identity)

Show code and output for `expr`.
Process the output by applying `post` or `convert_output` to it.
Then, post-process the output by applying `post` to it.
"""
function sco(expr::AbstractString;
        M=Main,
        process::Union{Nothing,Function}=nothing,
        post::Function=identity)
    code = remove_hide_comment(expr)
    code = code_block(strip(code))
    out = eval_convert(expr, M, process, post)
    """
    $code
    $out
    """
end

"""
    scob(expr::AbstractString; M=Main)

Show code and output in a block for `expr`.
"""
function scob(expr::AbstractString; M=Main)
    post = output_block
    sco(expr; M, post)
end

"""
    sc(expr::AbstractString; M=Main)

Show only code for `expr`, that is, evaluate `expr` but hide the output.
"""
function sc(expr::AbstractString; M=Main)
    eval_convert(expr, M)
    code = remove_hide_comment(expr)
    code = code_block(strip(code))
end
