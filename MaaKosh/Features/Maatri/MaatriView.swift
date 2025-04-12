import SwiftUI

struct MaatriView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Maatri AI Assistant")
                    .font(AppFont.titleMedium())
                    .padding()
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.pink.opacity(0.7))
                    .padding()
                
                Text("Your personal maternal health assistant")
                    .font(AppFont.body())
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Maatri")
        }
    }
}

struct MaatriView_Previews: PreviewProvider {
    static var previews: some View {
        MaatriView()
    }
} 