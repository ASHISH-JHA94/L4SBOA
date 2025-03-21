# L4SBOA: TeleHealth Over L4S.

**L4SBOA** (pronounced [Lisboa](https://pt.wikipedia.org/wiki/Lisboa)) is an L4S-based experimental network framework. We use L4SBOA as a prototype for network optimization developments in practice for various telehealth applications – sending DICOM images for diagnostics (high volume of data but tolerance for high latency), telemonitoring via wearable devices (low volume of data but demand for low latency), televisits (a video call through apps such as Zoom – high volume of data and demand for high latency). As a result of this project, we will understand whether we need any optimizations for L4S to use for telehealth applications and potential alternative approaches. 

Low Latency, Low Loss, and Scalable Throughput (L4S) Internet Service [1](https://datatracker.ietf.org/doc/rfc9330/), [2](http://www.watersprings.org/pub/id/draft-ietf-tsvwg-l4s-arch-06.html), [3](http://www.ring.gr.jp/archives/doc/RFC/rfc9330.pdf) has shown promising performance, by rethinking congestion control. Can we have a telehealth deployment with pairs of L4S nodes? Perhaps starting with something simple, such as two DICOM endpoints to send radiographic images in between? [Linux kernel with L4S patches](https://github.com/L4STeam/linux) can be a good point to start for the endpoints. How L4S, with telehealth and other applications, as well as classic non-L4S traffic, share the network will be an interesting test. 

As rural Alaska is largely unconnected by the road network, people often need to fly into larger towns such as Fairbanks and Anchorage for their healthcare needs. This state of affairs has steered the telehealth initiatives in Alaska much more than elsewhere in the US. Our research partners from healthcare organizations such as [Alaska Native Tribal Health Consortium (ANTHC)](https://www.anthc.org/) utilize telehealth in their daily operations. Improved telehealth access and performance can significantly benefit the patients and providers in terms of patient satisfaction and comfort.



Congestion Control has been of enormous interest to computing since the 80s when congestion collapses were first noticed. Many solutions were deployed to solve this problem, it was still however noticed they were just not sufficient. At the very base of this inadequacies were three popular constraints; loss, latency and throughput. Most congestion control algorithms can't guarantee low loss, low latency and scalable throughput. L4S signifies one of the recent summits of researches on congestion control and it promises low loss, low latency and scalable throughput. These claims seem to have been attested to and evidenced by multiple researchers. 

Alaska is the largest state in the United States of America and is said to be larger than 179 recognised countries. Aside it's huge land mass, its has one of the smallest population in the United States of America. This points to low population density and multiple remote areas needing basic amenities like healthcare. Thanks to the internet, telemedicine is an avenue remote areas can be served with healthcare. The biggest impedements to telehealth in remote areas are loss, throughput and latency.

This work aimed to investigate the claims of L4S in the first instance and eventually the improvements it brings to telehealth deployments. The telehalth component of this work is in three phases; tele health consultations, DICOM imaging and wearable devices. For Google Summer Of Code 2024, we were able to satisfactorily evaluate the first phase which is the tele health consulatation component of the research.


# L4SBOA Frontend Setup

## Setting Up the React Frontend

To run the React frontend locally, follow these steps:

### Prerequisites
Ensure you have the following installed on your system:
- [Node.js](https://nodejs.org/) (Recommended version: 16 or later)
- npm (Comes with Node.js)

### Installation Steps
1. **Clone the repository (if not already cloned):**
   ```sh
   git clone https://github.com/your-repo/L4SBOA.git
   cd L4SBOA
   ```

   ```

2. **Install dependencies:**
   ```sh
   npm install or npm i
   ```

4. **Start the development server:**
   ```sh
   npm start
   ```
To set up the L4S Kernel server locally, follow the instructions in [L4SKernelPatchSetUp.md](./L4SkernelPatchSetUp.md).
