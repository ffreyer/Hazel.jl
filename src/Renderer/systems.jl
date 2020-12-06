# This file is for things that mess with overseer more directly

function update!(app, s::Overseer.Stage, m::Overseer.AbstractLedger, ts)
    for s in last(s)
        update!(app, s, m, ts)
    end
end

function update!(app, m::Overseer.AbstractLedger, ts)
	for stage in Overseer.stages(m)
		update!(app, stage, m, ts)
	end
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
