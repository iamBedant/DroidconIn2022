import SwiftUI
import shared
import Combine



private let log = koin.loggerWithTag(tag: "ViewController")


class ObservableScheduleModel : ObservableObject {
    private var viewModel : ScheduleCallbackViewModel?
    
    @Published
    var loading = false
    
    @Published
    var schedules: [Session]?
    
    @Published
    var error: String?
    
    private var cancellables = [AnyCancellable]()


    func activate(){
        let viewModel = KotlinDependencies.shared.getScheduleViewModel()
        
        doPublish(viewModel.schedules) { [weak self] scheduleState in
            self?.loading = scheduleState.isLoading
            self?.schedules = scheduleState.sessions
            self?.error = scheduleState.error

            if let schedules = scheduleState.sessions {
                log.d(message: {"View updating with \(schedules.count) Sessions"})
            }
            if let errorMessage = scheduleState.error {
                log.e(message: {"Displaying error: \(errorMessage)"})
            }
        }.store(in: &cancellables)
        
        self.viewModel = viewModel
    }
    
    func refresh() {
        viewModel?.refreshSchedule()
    }
    
    func deactivate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        viewModel?.clear()
        viewModel = nil
    }
    
}


struct ContentView: View {
    @ObservedObject
    var observableModel = ObservableScheduleModel()
	var body: some View {
        ScheduleListContent(
            loading: observableModel.loading,
            sessions: observableModel.schedules,
            error: observableModel.error
        ).onAppear(perform: {
            observableModel.activate()
            observableModel.refresh()
        })
        .onDisappear(perform: {
            observableModel.deactivate()
        })
	}
}

struct ScheduleListContent: View {
    var loading: Bool
    var sessions: [Session]?
    var error: String?
    
    var body: some View {
        ZStack{
            VStack{
                if let sessions = sessions {
                    List(sessions, id: \.id){ session in
                        SessionRowView(session: session)
                    }
                }
            }
        }
    }
}


struct SessionRowView: View {
    var session: Session
    
    var body: some View {
        VStack{
            Text(session.title)
            Text(getSessionSpeakers(speakers: session.speakers))
            Text(getSessionTags(tags: session.tags))
        }
    }
}

func getSessionSpeakers(speakers: [Speaker]) -> String{
    var speakerString: String = ""
    for speaker in speakers{
        speakerString += "\(speaker.name) |"
    }
    return speakerString
}

func getSessionTags(tags: [Tags]) -> String{
    var tagString: String = ""
    for tag in tags{
        tagString += "\(tag.displayName) |"
    }
    return tagString
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
