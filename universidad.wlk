object aprobada {
	method estaAprobada() = true
}

object desaprobada {
	method estaAprobada() = false
}

class Cursada {
	const property materia
	const property nota
	var property estado = null

	method estado() {
		return if (estado != null) estado else self.calcularEstado()
	}

	method calcularEstado() {
		return if (nota >= 6) aprobada else desaprobada
	}

	method estaAprobada() = self.estado().estaAprobada()

	method creditosMateria() = materia.creditos()
}

class Carrera {
	const property materias = #{}

	method validarAgregarMateria(materia) {
		if (self.contieneMateria(materia)) {
			self.error("La materia ya pertenece a la carrera")
		}
	}

	method agregarMateria(materia) {
		self.validarAgregarMateria(materia)
		materias.add(materia)
		materia.carrera(self)
	}

	method contieneMateria(materia) = materias.contains(materia)

	method materiasDeAño(unAño) = self.filtrarMateriasPorAño(unAño)

	method filtrarMateriasPorAño(unAño) {
		return materias.filter({ m => m.esDeAño(unAño) })
	}
}


class Materia {
	var property carrera = null
	var property año = 1
	var property creditos = 0
	var property requisito = sinRequisito
	const property inscriptos = #{}

	method esDeAño(unAño) = año == unAño

	method estaInscripto(estudiante) = inscriptos.contains(estudiante)

	method perteneceACarreraDe(estudiante) = estudiante.estaInscriptoEnCarrera(carrera)

	method estaAprobadaPor(estudiante) = estudiante.tieneAprobada(self)

	method cumpleRequisito(estudiante) = requisito.cumple(estudiante, self)

	method puedeInscribir(estudiante) {
		return self.perteneceACarreraDe(estudiante)
			and not self.estaAprobadaPor(estudiante)
			and not self.estaInscripto(estudiante)
			and self.cumpleRequisito(estudiante)
	}

	method validarInscripcion(estudiante) {
		if (not self.puedeInscribir(estudiante)) {
			self.error("El estudiante no cumple con las condiciones para inscribirse a " + self.toString())
		}
	}

	method inscribir(estudiante) {
		self.validarInscripcion(estudiante)
		inscriptos.add(estudiante)
	}
}

class Estudiante {
	const property carreras = #{}
	const property cursadas = []

	method estaInscriptoEnCarrera(carrera) = carreras.contains(carrera)

	method validarInscribirACarrera(carrera) {
		if (self.estaInscriptoEnCarrera(carrera)) {
			self.error("Ya se encuentra inscripto a la carrera")
		}
	}

	method inscribirACarrera(carrera) {
		self.validarInscribirACarrera(carrera)
		carreras.add(carrera)
	}

	method materiaPerteneceACarrerasInscriptas(materia) = self.algunaCarreraTieneMateria(materia)

	method algunaCarreraTieneMateria(materia) {
		return carreras.any({ c => c.contieneMateria(materia) })
	}

	method validarNota(nota) {
		if (not nota.between(1, 10)) {
			self.error("La nota debe ser un número entre 1 y 10")
		}
	}

	method validarPertenenciaDeMateria(materia) {
		if (not self.materiaPerteneceACarrerasInscriptas(materia)) {
			self.error("La materia no pertenece a ninguna de las carreras inscriptas")
		}
	}

	method validarNoAprobada(materia) {
		if (self.tieneAprobada(materia)) {
			self.error("La materia ya se encuentra aprobada")
		}
	}

	method validarRegistroCursada(materia, nota) {
		self.validarNota(nota)
		self.validarPertenenciaDeMateria(materia)
		self.validarNoAprobada(materia)
	}

	method estadoSegunNota(nota) = if (nota >= 6) aprobada else desaprobada

	method registrarCursada(materia, nota) {
		self.validarRegistroCursada(materia, nota)
		cursadas.add(new Cursada(materia = materia, nota = nota, estado = self.estadoSegunNota(nota)))
	}

	method cursadasDe(materia) = self.filtrarCursadasPorMateria(materia)

	method filtrarCursadasPorMateria(materia) {
		return cursadas.filter({ c => c.materia() == materia })
	}

	method tieneAprobada(materia) = self.tieneCursadaAprobadaDe(materia)

	method tieneCursadaAprobadaDe(materia) {
		return self.cursadasDe(materia).any({ c => c.estaAprobada() })
	}

	method cursadasAprobadas() = self.filtrarCursadasAprobadas()

	method filtrarCursadasAprobadas() {
		return cursadas.filter({ c => c.estaAprobada() })
	}

	method materiasAprobadas() = self.mapearMateriasDeCursadas(self.cursadasAprobadas())

	method mapearMateriasDeCursadas(unasCursadas) {
		return unasCursadas.map({ c => c.materia() })
	}

	method validarInscripcionACarrera(carrera) {
		if (not self.estaInscriptoEnCarrera(carrera)) {
			self.error("El estudiante no está inscripto en la carrera")
		}
	}

	method cursadasAprobadasDeCarrera(carrera) {
		self.validarInscripcionACarrera(carrera)
		return self.filtrarCursadasPorCarrera(self.cursadasAprobadas(), carrera)
	}

	method filtrarCursadasPorCarrera(unasCursadas, carrera) {
		return unasCursadas.filter({ c => carrera.contieneMateria(c.materia()) })
	}

	method cantidadMateriasAprobadasDeCarrera(carrera) {
		return self.cursadasAprobadasDeCarrera(carrera).size()
	}

	method validarTieneAprobadasEnCarrera(carrera) {
		if (self.cursadasAprobadasDeCarrera(carrera).isEmpty()) {
			self.error("No tiene materias aprobadas en la carrera")
		}
	}

	method sumatoriaNotasDeCarrera(carrera) {
		return self.cursadasAprobadasDeCarrera(carrera).sum({ c => c.nota() })
	}

	method promedioDeCarrera(carrera) {
		self.validarTieneAprobadasEnCarrera(carrera)
		return self.sumatoriaNotasDeCarrera(carrera) / self.cantidadMateriasAprobadasDeCarrera(carrera)
	}

	method creditosEnCarrera(carrera) = self.sumatoriaCreditosDeCarrera(carrera)

	method sumatoriaCreditosDeCarrera(carrera) {
		return self.cursadasAprobadasDeCarrera(carrera).sum({ c => c.creditosMateria() })
	}

	method cantidadMateriasAprobadas() = self.cursadasAprobadas().size()

	method validarTieneAprobadas() {
		if (self.cursadasAprobadas().isEmpty()) {
			self.error("No tiene materias aprobadas")
		}
	}

	method sumatoriaNotasAprobadas() {
		return self.cursadasAprobadas().sum({ c => c.nota() })
	}

	method promedio() {
		self.validarTieneAprobadas()
		return self.sumatoriaNotasAprobadas() / self.cantidadMateriasAprobadas()
	}

	method materiasHabilitadas(carrera) {
		self.validarInscripcionACarrera(carrera)
		return self.filtrarMateriasHabilitadas(carrera)
	}

	method filtrarMateriasHabilitadas(carrera) {
		return carrera.materias().filter({ m => m.puedeInscribir(self) })
	}
}

object sinRequisito {
	method cumple(estudiante, materia) = true
}

class Correlativas {
	var property correlativas = #{}

	method cumple(estudiante, materia) = self.estanTodasAprobadas(estudiante)

	method estanTodasAprobadas(estudiante) {
		return correlativas.all({ m => estudiante.tieneAprobada(m) })
	}
}

class PorCreditos {
	const property creditosNecesarios

	method cumple(estudiante, materia) = self.alcanzaCreditos(estudiante, materia)

	method alcanzaCreditos(estudiante, materia) {
		return estudiante.creditosEnCarrera(materia.carrera()) >= creditosNecesarios
	}
}

object porAñoAnterior {
	method materiasDelAñoAnterior(materia) {
		return materia.carrera().materiasDeAño(materia.año() - 1)
	}

	method aproboAñoAnteriorCompleto(estudiante, materia) {
		return self.materiasDelAñoAnterior(materia).all({ m => estudiante.tieneAprobada(m) })
	}

	method cumple(estudiante, materia) {
		return materia.año() <= 1 or self.aproboAñoAnteriorCompleto(estudiante, materia)
	}
}