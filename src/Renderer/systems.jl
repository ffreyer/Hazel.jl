# This file is for things that mess with overseer more directly

function update_runtime!(app, s::Overseer.Stage, m::AbstractLedger, ts)
    for s in last(s)
        update_runtime!(app, s, m, ts)
    end
end

function update_runtime!(app, m::AbstractLedger, ts)
	for stage in Overseer.stages(m)
		update_runtime!(app, stage, m, ts)
	end
end

function update_editor!(app, s::Overseer.Stage, m::AbstractLedger, camera, ts)
    for s in last(s)
        update_editor!(app, s, m, camera, ts)
    end
end

function update_editor!(app, m::AbstractLedger, camera, ts)
	for stage in Overseer.stages(m)
		update_editor!(app, stage, m, camera, ts)
	end
end

update_runtime!(app, s::System, m::AbstractLedger, ts) = update!(app, s, m, ts)
function update_editor!(app, s::System, m::AbstractLedger, camera, ts)
    @debug "update_editor! not implemented for $(typeof(s))"
    nothing
end

struct RunScript <: System end
requested_components(::RunScript) = (ScriptComponent,)
function update!(app, ::RunScript, reg::Overseer.AbstractLedger, ts)
    scripts = reg[ScriptComponent]
    for e in @entities_in(scripts)
        scripts[e].update!(app, Entity(reg, e), ts)
    end
    nothing
end